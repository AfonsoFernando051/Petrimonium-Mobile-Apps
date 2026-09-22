/// A typical single-lesson XP reward, shown as an illustrative number in
/// onboarding screens that run before the user has any real progress (and,
/// for `AcademyIntroScreen`, before the Academy catalog may even be
/// reachable over the network). Every lesson in the real catalog is worth
/// 20 XP today — not derived from the catalog itself so these screens don't
/// depend on a network fetch for a decorative number.
const int kStandardLessonXpReward = 20;

/// How many schools the onboarding track shows before collapsing the rest
/// into a single "mais N escolas" line. Onboarding is a taste of the
/// journey, not the catalog: the curriculum has ~19 schools today and a
/// step that scrolls through all of them buries its own CTA.
const int kOnboardingTrackPreviewSchools = 4;
