import Foundation

struct PresetTrack: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let category: String
    let icon: String
    let lines: [String]
    let isSOS: Bool

    var script: ManifestationScript {
        ManifestationScript(
            title: title,
            opening: "Let your shoulders drop. Nothing else needs you right now.",
            lines: lines,
            closing: "Stay here as long as you need. Sleep well.",
            minutes: 8
        )
    }

    var fileName: String {
        "preset-\(id).caf"
    }
}

enum PresetCatalog {
    static let tracks: [PresetTrack] = [
        PresetTrack(id: "deep-sleep", title: "Deep Sleep", subtitle: "Slide under the surface", category: "Sleep", icon: "moon.zzz.fill", lines: [
            "Your body is heavy, and that is good.",
            "Each breath takes you further from the day.",
            "You do not need to solve anything tonight.",
            "Rest is the work you are doing now.",
            "The room is quiet, and you are safe in it.",
            "You let your thoughts drift like clouds.",
            "Sleep is already coming closer.",
            "You have nothing to prove tonight."
        ], isSOS: false),
        PresetTrack(id: "self-worth", title: "Self Worth", subtitle: "Speak to yourself gently", category: "Confidence", icon: "heart.fill", lines: [
            "You are worthy without performing.",
            "You do not have to earn your own kindness.",
            "You are allowed to take up space.",
            "Your worth is not a moving target.",
            "You speak to yourself the way you speak to someone you love.",
            "You can be proud and still be learning.",
            "You are enough before anything changes.",
            "You belong in your own life."
        ], isSOS: false),
        PresetTrack(id: "abundance", title: "Abundance", subtitle: "Welcome steady support", category: "Money", icon: "sparkles", lines: [
            "You are open to what sustains you.",
            "Money can be simple in your life.",
            "You make room without gripping.",
            "You trust yourself with what arrives.",
            "You are worth being paid well.",
            "You let abundance be ordinary.",
            "You receive easily and give cleanly.",
            "Your safety is growing quietly."
        ], isSOS: false),
        PresetTrack(id: "easy-love", title: "Easy Love", subtitle: "Love without chasing", category: "Love", icon: "infinity", lines: [
            "You are easy to love.",
            "You do not need to chase anything that belongs to you.",
            "You are open to steady affection.",
            "You let the right person feel simple to choose.",
            "You are soft, and you are clear.",
            "You do not abandon yourself for connection.",
            "You receive love without shrinking.",
            "Connection is allowed to feel calm."
        ], isSOS: false),
        PresetTrack(id: "career-flow", title: "Career Flow", subtitle: "The right door opens", category: "Career", icon: "briefcase.fill", lines: [
            "Your work is finding its right shape.",
            "You trust the pace of your becoming.",
            "The next step is enough for today.",
            "You bring value wherever you focus.",
            "You are allowed to begin before you feel ready.",
            "Clarity comes in usable pieces.",
            "You do not need to force what fits.",
            "You are building something that respects your life."
        ], isSOS: false),
        PresetTrack(id: "release", title: "Release", subtitle: "Let the old thing go", category: "Calm", icon: "wind", lines: [
            "You release what has already finished.",
            "You do not carry what was never yours.",
            "You can let go without losing yourself.",
            "Your exhale is permission.",
            "You are allowed to move on quietly.",
            "The past does not need to be replayed.",
            "You choose the lighter version of this.",
            "You make space for what comes next."
        ], isSOS: false),
        PresetTrack(id: "sos-calm", title: "SOS Calm", subtitle: "Two minutes to steady", category: "SOS", icon: "waveform.path.ecg", lines: [
            "You are safe right now, in this moment.",
            "You do not need to fix everything.",
            "Let your jaw soften.",
            "Let your shoulders fall away from your ears.",
            "Breathe in slowly, and let the breath out be longer.",
            "You are here, and this will pass.",
            "One more slow breath, exactly like that.",
            "You are already coming back to yourself."
        ], isSOS: true),
        PresetTrack(id: "morning-moon", title: "Morning Moon", subtitle: "A gentle start", category: "Calm", icon: "sun.horizon.fill", lines: [
            "You wake without needing to prove anything.",
            "You have time for one honest breath.",
            "Today can be simple and still be good.",
            "You choose your own rhythm.",
            "You keep what matters close.",
            "You are allowed to move slowly and still arrive.",
            "You meet today with an open hand.",
            "You are already enough for this morning."
        ], isSOS: false),
        PresetTrack(id: "anxiety-off", title: "Quiet Mind", subtitle: "Softer thoughts", category: "Calm", icon: "brain.head.profile", lines: [
            "Your thoughts are moving through you, not defining you.",
            "You do not need to follow every one of them.",
            "You choose the thought that feels steadier.",
            "Your mind is allowed to rest.",
            "You can be uncertain and still be safe.",
            "You let the noise become quieter.",
            "You come back to the body.",
            "You are more spacious than your worry."
        ], isSOS: false),
        PresetTrack(id: "confidence", title: "Confidence", subtitle: "Stand where you stand", category: "Confidence", icon: "figure.stand", lines: [
            "You take up space without apology.",
            "Your voice is worth hearing.",
            "You do not need to be smaller to be loved.",
            "You trust what you bring.",
            "You can be certain and still be gentle.",
            "You speak with a calm spine.",
            "You are allowed to be fully seen.",
            "You stand in your own authority."
        ], isSOS: false),
        PresetTrack(id: "forgiveness", title: "Forgiveness", subtitle: "For you, not them", category: "Healing", icon: "leaf.fill", lines: [
            "You release the weight of what happened.",
            "You can be free without an apology.",
            "You let yourself off a hook you never deserved.",
            "You are allowed to move forward.",
            "You do not owe anyone your smallness.",
            "You choose softness for your own sake.",
            "You give yourself the grace you needed then.",
            "You are lighter now."
        ], isSOS: false),
        PresetTrack(id: "gratitude", title: "Gratitude", subtitle: "Notice what holds you", category: "Calm", icon: "sparkles", lines: [
            "You notice what is quietly holding you.",
            "There are good things you did not have to earn.",
            "You let gratitude be small and real.",
            "You thank the ordinary parts of today.",
            "You receive the simple good in front of you.",
            "You are supported in ways you can name.",
            "You let this be enough.",
            "You rest in what is already here."
        ], isSOS: false),
        PresetTrack(id: "boundaries", title: "Boundaries", subtitle: "Kind, clear, firm", category: "Healing", icon: "hand.raised.fill", lines: [
            "You can say no without explaining.",
            "Your limits are allowed to be quiet.",
            "You do not owe anyone access to you.",
            "You protect your peace without guilt.",
            "You can be kind and still be firm.",
            "You choose what is yours to carry.",
            "You let other people own their feelings.",
            "You are allowed to take care of yourself first."
        ], isSOS: false),
        PresetTrack(id: "new-chapter", title: "New Chapter", subtitle: "Begin before ready", category: "Career", icon: "book.closed.fill", lines: [
            "You do not need the whole map.",
            "You begin with the next honest step.",
            "You are allowed to be a beginner.",
            "You trust what made you start.",
            "You make room for a new version of your life.",
            "You can change your mind as you learn.",
            "You meet the unknown with curiosity.",
            "You are already in the new chapter."
        ], isSOS: false),
        PresetTrack(id: "sleep-anchor", title: "Sleep Anchor", subtitle: "For restless nights", category: "Sleep", icon: "anchor", lines: [
            "You are anchored in this bed.",
            "Your breath is the rope back to now.",
            "You do not need to earn sleep.",
            "You let the day be finished.",
            "You are safe in the dark.",
            "You release the last ten minutes.",
            "You let your body lead.",
            "You are falling asleep gently."
        ], isSOS: false),
        PresetTrack(id: "joy", title: "Small Joy", subtitle: "Let good be good", category: "Calm", icon: "sun.max.fill", lines: [
            "You do not need to earn this good feeling.",
            "You let delight be simple.",
            "You are allowed to be happy without a reason.",
            "You notice what feels light.",
            "You keep the small things close.",
            "You let yourself enjoy this.",
            "You make room for more of the same.",
            "You receive joy without bracing."
        ], isSOS: false),
        PresetTrack(id: "body-ease", title: "Body Ease", subtitle: "Soften the tension", category: "Calm", icon: "figure.mind.and.body", lines: [
            "You let your body be heavy.",
            "You release your shoulders.",
            "You let your hands open.",
            "You give your jaw permission to soften.",
            "You notice where you are holding on.",
            "You do not need to carry tension to be safe.",
            "You breathe into the soft places.",
            "You let the body rest."
        ], isSOS: false),
        PresetTrack(id: "relationship", title: "Warm Connection", subtitle: "Come closer, calmly", category: "Love", icon: "person.2.fill", lines: [
            "You are open to being known.",
            "You do not need to perform to be chosen.",
            "You let closeness be safe.",
            "You speak honestly without shrinking.",
            "You allow the right person to meet you.",
            "You keep your own center.",
            "You receive affection without flinching.",
            "You are worth the effort that feels easy."
        ], isSOS: false),
        PresetTrack(id: "money-ground", title: "Financial Ground", subtitle: "Steady feet", category: "Money", icon: "banknote.fill", lines: [
            "You are grounded where you stand.",
            "You can build slowly and still succeed.",
            "You trust yourself with small steps.",
            "You make decisions with a calm mind.",
            "You let money be a tool, not a threat.",
            "You are allowed to ask for what you are worth.",
            "You keep good records and a soft heart.",
            "You are building real security."
        ], isSOS: false),
        PresetTrack(id: "clarity", title: "Clarity", subtitle: "One honest answer", category: "Calm", icon: "light.beacon.max.fill", lines: [
            "You do not need the entire answer.",
            "You let the next step become clear.",
            "You can wait without falling behind.",
            "You listen to the calm voice in you.",
            "You choose the honest answer.",
            "You let clarity arrive in pieces.",
            "You do not force what has not opened.",
            "You see enough for today."
        ], isSOS: false),
        PresetTrack(id: "strength", title: "Quiet Strength", subtitle: "Steady, not hard", category: "Confidence", icon: "shield.fill", lines: [
            "You are strong without becoming hard.",
            "You can be soft and still stand.",
            "You do not need to fight for your place.",
            "You meet difficulty with a steady breath.",
            "You keep your own promises.",
            "You do not abandon yourself under pressure.",
            "You can rest and still be powerful.",
            "You are quiet and unmoved."
        ], isSOS: false),
        PresetTrack(id: "home-feeling", title: "Home Feeling", subtitle: "Safe inside yourself", category: "Healing", icon: "house.fill", lines: [
            "You are at home in your own body.",
            "You do not need to leave yourself to be loved.",
            "You belong to this life.",
            "You make a safe place with your breath.",
            "You can return here anytime.",
            "You are not an outsider in your own story.",
            "You settle into yourself.",
            "You rest on your own floor."
        ], isSOS: false),
        PresetTrack(id: "sunday-reset", title: "Sunday Reset", subtitle: "Begin again softly", category: "Calm", icon: "calendar", lines: [
            "You let the week be finished.",
            "You do not need to carry everything into the next one.",
            "You choose what you actually want to keep.",
            "You release the rest with grace.",
            "You start again with a clean breath.",
            "You make space for the week you want.",
            "You are allowed to reset without shame.",
            "You meet tomorrow from a quiet place."
        ], isSOS: false),
        PresetTrack(id: "future-self", title: "Future Self", subtitle: "Meet who you become", category: "Confidence", icon: "figure.walk", lines: [
            "You know the version of you that is coming.",
            "She is calm, and she is not rushing.",
            "He meets life with an open hand.",
            "You can feel that future self in your posture.",
            "You take one step as that person today.",
            "You do not need to become overnight.",
            "You are already on the way.",
            "You let the future meet you here."
        ], isSOS: false)
    ]
}
