// Carrega um .riv com o runtime C++ oficial, dirige a state machine por comandos
// no stdin e grava as chamadas drawImage (id, matriz, opacidade) em JSON por quadro.
#include "rive/file.hpp"
#include "rive/artboard.hpp"
#include "rive/animation/state_machine_instance.hpp"
#include "rive/animation/state_machine_input_instance.hpp"
#include "rive/animation/linear_animation.hpp"
#include "rive/animation/state_machine.hpp"
#include "rive/renderer.hpp"
#include "utils/no_op_factory.hpp"
#include <cstdio>
#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>
using namespace rive;

struct RecImage : public RenderImage {
    int id;
    RecImage(int i, int w, int h) : id(i) { m_Width = w; m_Height = h; }
};
struct RecFactory : public NoOpFactory {
    int next = 0;
    rcp<RenderImage> decodeImage(Span<const uint8_t> d) override {
        int w = 0, h = 0;
        if (d.size() > 24) {
            w = (d[16] << 24) | (d[17] << 16) | (d[18] << 8) | d[19];
            h = (d[20] << 24) | (d[21] << 16) | (d[22] << 8) | d[23];
        }
        return make_rcp<RecImage>(next++, w, h);
    }
};
struct Draw { int id; Mat2D m; float op; };
struct RecRenderer : public Renderer {
    std::vector<Mat2D> stack{Mat2D()};
    std::vector<float> ops{1.0f};
    std::vector<Draw> draws;
    void save() override { stack.push_back(stack.back()); ops.push_back(ops.back()); }
    void restore() override { stack.pop_back(); ops.pop_back(); }
    void modulateOpacity(float o) override { ops.back() *= o; }
    void transform(const Mat2D& t) override { stack.back() = stack.back() * t; }
    void drawPath(RenderPath*, RenderPaint*) override {}
    void clipPath(RenderPath*) override {}
    void drawImage(const RenderImage* img, ImageSampler, BlendMode, float op) override {
        draws.push_back({static_cast<const RecImage*>(img)->id, stack.back(), op * ops.back()});
    }
    void drawImageMesh(const RenderImage*, ImageSampler, rcp<RenderBuffer>, rcp<RenderBuffer>,
                       rcp<RenderBuffer>, uint32_t, uint32_t, BlendMode, float) override {}
};

int main(int argc, char** argv) {
    std::ifstream f(argv[1], std::ios::binary);
    std::vector<uint8_t> bytes((std::istreambuf_iterator<char>(f)), {});
    RecFactory factory;
    ImportResult res;
    auto file = File::import(bytes, &factory, &res);
    if (!file) { printf("{\"error\":\"import failed %d\"}\n", (int)res); return 1; }
    auto ab = file->artboardDefault();
    printf("{\"artboard\":\"%s\",\"w\":%g,\"h\":%g,\"animations\":[", ab->name().c_str(), ab->width(), ab->height());
    for (size_t i = 0; i < ab->animationCount(); i++)
        printf("%s\"%s\"", i ? "," : "", ab->animation(i)->name().c_str());
    printf("],\"stateMachines\":[");
    for (size_t i = 0; i < ab->stateMachineCount(); i++)
        printf("%s\"%s\"", i ? "," : "", ab->stateMachine(i)->name().c_str());
    printf("],\"defaultSM\":%d}\n", ab->defaultStateMachineIndex());
    auto sm = ab->defaultStateMachine();
    if (!sm) { printf("{\"error\":\"no default state machine\"}\n"); return 1; }
    printf("{\"inputs\":[");
    for (size_t i = 0; i < sm->inputCount(); i++) printf("%s\"%s\"", i ? "," : "", sm->input(i)->name().c_str());
    printf("]}\n");
    sm->advanceAndApply(0);
    std::string line;
    while (std::getline(std::cin, line)) {
        std::istringstream ss(line); std::string cmd; ss >> cmd;
        if (cmd == "num") { std::string n; float v; ss >> n >> v; sm->getNumber(n)->value(v); }
        else if (cmd == "bool") { std::string n; int v; ss >> n >> v; sm->getBool(n)->value(v != 0); }
        else if (cmd == "adv") { float t; ss >> t; sm->advanceAndApply(t); }
        else if (cmd == "dump") {
            std::string tag; ss >> tag;
            RecRenderer r; ab->draw(&r);
            printf("{\"tag\":\"%s\",\"draws\":[", tag.c_str());
            for (size_t i = 0; i < r.draws.size(); i++) {
                auto& d = r.draws[i];
                printf("%s[%d,%g,%g,%g,%g,%g,%g,%g]", i ? "," : "", d.id, d.m[0], d.m[1], d.m[2], d.m[3], d.m[4], d.m[5], d.op);
            }
            printf("]}\n");
        }
    }
    return 0;
}
