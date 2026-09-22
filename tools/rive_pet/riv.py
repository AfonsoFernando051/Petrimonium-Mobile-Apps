"""Leitura/escrita mínima do formato binário .riv (runtime v7)."""
import json, os, struct
# rive_defs.json: typeKeys/propertyKeys/tipos extraídos de rive-runtime/include/rive/generated
D = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'rive_defs.json')))
CLS = D['classes']; FT = {int(k): v for k, v in D['ftype'].items()}
BY_TK = {c['typeKey']: n for n, c in CLS.items() if c['typeKey'] is not None}
PROPNAME = {}
for n, c in CLS.items():
    for p, k in c['props'].items(): PROPNAME[k] = f'{n}.{p}'
FIELD_ID = {'Uint': 0, 'Id': 0, 'Bool': 0, 'Int': 0, 'String': 1, 'Bytes': 1, 'Double': 2, 'Color': 3}

def all_props(cls):
    out = {}
    while cls in CLS:
        for p, k in CLS[cls]['props'].items(): out.setdefault(p, k)
        cls = CLS[cls]['parent']
    return out

class Reader:
    def __init__(s, b): s.b = b; s.i = 0
    def byte(s): v = s.b[s.i]; s.i += 1; return v
    def varuint(s):
        r = sh = 0
        while True:
            x = s.byte(); r |= (x & 0x7f) << sh; sh += 7
            if not x & 0x80: return r
    def u32(s): v = struct.unpack_from('<I', s.b, s.i)[0]; s.i += 4; return v
    def f32(s): v = struct.unpack_from('<f', s.b, s.i)[0]; s.i += 4; return v
    def raw(s): n = s.varuint(); v = s.b[s.i:s.i+n]; s.i += n; return v

def read(path):
    r = Reader(open(path, 'rb').read())
    assert r.b[:4] == b'RIVE'; r.i = 4
    major, minor, fid = r.varuint(), r.varuint(), r.varuint()
    keys = []
    while True:
        k = r.varuint()
        if k == 0: break
        keys.append(k)
    toc = {}; bit = 8; cur = 0
    for k in keys:
        if bit == 8: cur = r.u32(); bit = 0
        toc[k] = (cur >> bit) & 3; bit += 2
    objs = []
    while r.i < len(r.b):
        tk = r.varuint(); props = []
        while True:
            pk = r.varuint()
            if pk == 0: break
            t = FT.get(pk)
            fid_ = FIELD_ID[t] if t else toc.get(pk)
            if t == 'Bool': v = r.byte()
            elif fid_ == 0: v = r.varuint()
            elif fid_ == 1: v = r.raw(); v = v.decode('utf8', 'replace') if t != 'Bytes' else f'<{len(v)} bytes>'
            elif fid_ == 2: v = round(r.f32(), 4)
            elif fid_ == 3: v = hex(r.u32())
            else: raise ValueError(f'unknown prop {pk}')
            props.append((PROPNAME.get(pk, pk), v))
        objs.append((BY_TK.get(tk, tk), props))
    return (major, minor), objs

class Writer:
    def __init__(s): s.objs = []; s.keys = []
    def add(s, cls, **props):
        ap = all_props(cls); lst = []
        for p, v in props.items():
            k = ap[p] if p in ap else {'name': 138}[p]; lst.append((k, v))
            if k not in s.keys: s.keys.append(k)
        s.objs.append((CLS[cls]['typeKey'], lst)); return len(s.objs) - 1
    @staticmethod
    def vu(n):
        out = bytearray()
        while True:
            b = n & 0x7f; n >>= 7
            if n: out.append(b | 0x80)
            else: out.append(b); return bytes(out)
    def bytes(s, file_id=0):
        o = bytearray(b'RIVE') + s.vu(7) + s.vu(0) + s.vu(file_id)
        for k in s.keys: o += s.vu(k)
        o += s.vu(0)
        cur = bit = 0; words = []
        for i, k in enumerate(s.keys):
            cur |= FIELD_ID[FT[k]] << (2 * (i % 4))
            if i % 4 == 3: words.append(cur); cur = 0
        if len(s.keys) % 4: words.append(cur)
        for w in words: o += struct.pack('<I', w)
        for tk, props in s.objs:
            o += s.vu(tk)
            for k, v in props:
                o += s.vu(k); t = FT[k]
                if t == 'Bool': o.append(1 if v else 0)
                elif t in ('Uint', 'Id', 'Int'): o += s.vu(int(v))
                elif t == 'String': b = v.encode(); o += s.vu(len(b)) + b
                elif t == 'Bytes': o += s.vu(len(v)) + v
                elif t == 'Double': o += struct.pack('<f', float(v))
                elif t == 'Color': o += struct.pack('<I', v)
            o += s.vu(0)
        return bytes(o)

if __name__ == '__main__':
    import sys
    ver, objs = read(sys.argv[1]); print('version', ver)
    for i, (c, p) in enumerate(objs): print(i, c, p)
