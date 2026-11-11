pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Motion settings & reduced-motion support
    property bool reducedMotion: false
    readonly property int animDuration: reducedMotion ? 0 : 250

    // Core dimensional & spacing tokens
    readonly property int panelHeight: 40
    readonly property int bodyFontSize: 16
    readonly property int spacingSmall: 4
    readonly property int spacingMedium: 8
    readonly property int spacingLarge: 16
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusPill: 18

    // Typography tokens
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontUi: "Adwaita Sans"

    // Static fallback tokens (Nord dark palette foundation with WCAG AA compliance)
    readonly property color fallbackBg: "#2E3440"
    readonly property color fallbackSurfaceLow: "#353C4A"
    readonly property color fallbackSurface: "#3B4252"
    readonly property color fallbackSurfaceHigh: "#434C5E"
    readonly property color fallbackTextPrimary: "#ECEFF4"
    readonly property color fallbackTextSecondary: "#D8DEE9"
    readonly property color fallbackTextMuted: "#88C0D0"
    readonly property color fallbackAccent: "#81A1C1"
    readonly property color fallbackAccentContainer: "#4C566A"
    readonly property color fallbackOnAccent: "#2E3440" // Dark text on light accent provides 4.64:1 contrast (WCAG AA)

    // Active semantic tokens
    property color bgCanvas: fallbackBg
    property color surfaceLow: fallbackSurfaceLow
    property color surfaceContainer: fallbackSurface
    property color surfaceHigh: fallbackSurfaceHigh
    property color textPrimary: fallbackTextPrimary
    property color textSecondary: fallbackTextSecondary
    property color textMuted: fallbackTextMuted
    property color accent: fallbackAccent
    property color accentContainer: fallbackAccentContainer
    property color onAccent: fallbackOnAccent

    // Base translucent surface (for panels, floating cards, bars)
    readonly property color baseSurface: Qt.rgba(bgCanvas.r, bgCanvas.g, bgCanvas.b, 0.75)

    // Dynamic borders & interaction states
    readonly property color borderSubtle: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.12)
    readonly property color borderHighlight: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.28)
    readonly property color surfaceHover: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.08)
    readonly property color surfaceFocus: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.16)

    // Backward-compatibility aliases
    readonly property color backgroundColor: bgCanvas
    readonly property color textColor: textPrimary

    // Dynamic scheme state
    property bool dynamicSchemeActive: false

    function toLinear(val) {
        return val <= 0.04045 ? val / 12.92 : Math.pow((val + 0.055) / 1.055, 2.4);
    }

    function getWcagLuminance(c) {
        return 0.2126 * toLinear(c.r) + 0.7152 * toLinear(c.g) + 0.0722 * toLinear(c.b);
    }

    function getContrast(c1, c2) {
        const l1 = getWcagLuminance(c1);
        const l2 = getWcagLuminance(c2);
        const lighter = Math.max(l1, l2);
        const darker = Math.min(l1, l2);
        return (lighter + 0.05) / (darker + 0.05);
    }

    function isValidHex(str) {
        if (typeof str !== "string")
            return false;
        const clean = str.trim();
        return clean.length === 6 && /^[0-9a-fA-F]{6}$/.test(clean);
    }

    function resetToFallbacks() {
        root.bgCanvas = root.fallbackBg;
        root.surfaceLow = root.fallbackSurfaceLow;
        root.surfaceContainer = root.fallbackSurface;
        root.surfaceHigh = root.fallbackSurfaceHigh;
        root.textPrimary = root.fallbackTextPrimary;
        root.textSecondary = root.fallbackTextSecondary;
        root.textMuted = root.fallbackTextMuted;
        root.accent = root.fallbackAccent;
        root.accentContainer = root.fallbackAccentContainer;
        root.onAccent = root.fallbackOnAccent;
        root.dynamicSchemeActive = false;
    }

    FileView {
        id: schemeWatcher
        path: Quickshell.env("HOME") + "/.local/state/caelestia/scheme.json"
        watchChanges: true
        printErrors: false

        onFileChanged: reload()

        onLoaded: {
            try {
                const raw = text().trim();
                if (!raw) {
                    root.resetToFallbacks();
                    return;
                }
                const parsed = JSON.parse(raw);
                if (!parsed || !parsed.colours) {
                    root.resetToFallbacks();
                    return;
                }
                const c = parsed.colours;

                // Validate required tokens are valid 6-char hex
                if (!root.isValidHex(c.background) ||
                    !root.isValidHex(c.surfaceContainer) ||
                    !root.isValidHex(c.primary) ||
                    !root.isValidHex(c.onSurface || c.text) ||
                    !root.isValidHex(c.onPrimary)) {
                    console.warn("[Rice Theme] scheme.json contains missing or invalid required hex colors; using fallbacks");
                    root.resetToFallbacks();
                    return;
                }

                // Parse primary required colors
                const newBg = Qt.color("#" + c.background);
                const newSurface = Qt.color("#" + c.surfaceContainer);
                const newAccent = Qt.color("#" + c.primary);

                // Parse optional colors with verified fallbacks
                const hexSurfaceLow = root.isValidHex(c.surfaceContainerLow) ? c.surfaceContainerLow : c.surfaceContainer;
                const hexSurfaceHigh = root.isValidHex(c.surfaceContainerHigh) ? c.surfaceContainerHigh : c.surfaceContainer;
                const hexTextPrimary = root.isValidHex(c.onSurface) ? c.onSurface : (root.isValidHex(c.text) ? c.text : "ffffff");
                const hexTextSec = root.isValidHex(c.onSurfaceVariant) ? c.onSurfaceVariant : (root.isValidHex(c.subtext1) ? c.subtext1 : hexTextPrimary);
                const hexTextMuted = root.isValidHex(c.outline) ? c.outline : (root.isValidHex(c.subtext0) ? c.subtext0 : hexTextSec);
                const hexAccentContainer = root.isValidHex(c.primaryContainer) ? c.primaryContainer : c.primary;
                const hexOnAccent = root.isValidHex(c.onPrimary) ? c.onPrimary : "ffffff";

                const newSurfaceLow = Qt.color("#" + hexSurfaceLow);
                const newSurfaceHigh = Qt.color("#" + hexSurfaceHigh);
                let newTextPrimary = Qt.color("#" + hexTextPrimary);
                let newTextSec = Qt.color("#" + hexTextSec);
                let newTextMuted = Qt.color("#" + hexTextMuted);
                const newAccentContainer = Qt.color("#" + hexAccentContainer);
                let newOnAccent = Qt.color("#" + hexOnAccent);

                // WCAG AA Verification: Normal text requires >= 4.5:1 against surfaceContainer
                if (root.getContrast(newTextPrimary, newSurface) < 4.5) {
                    newTextPrimary = root.getWcagLuminance(newSurface) > 0.5 ? Qt.color("#111111") : Qt.color("#fcfcfc");
                }

                // WCAG AA Verification: Secondary text (minimum 4.5:1 for normal text)
                if (root.getContrast(newTextSec, newSurface) < 4.5) {
                    newTextSec = newTextPrimary;
                }

                // WCAG AA Verification: Normal-sized muted text & metadata requires >= 4.5:1 against surfaceContainer
                if (root.getContrast(newTextMuted, newSurface) < 4.5) {
                    if (root.getContrast(newTextSec, newSurface) >= 4.5) {
                        for (let step = 1; step <= 10; ++step) {
                            const factor = step / 10.0;
                            const r = newTextMuted.r + factor * (newTextSec.r - newTextMuted.r);
                            const g = newTextMuted.g + factor * (newTextSec.g - newTextMuted.g);
                            const b = newTextMuted.b + factor * (newTextSec.b - newTextMuted.b);
                            const candidate = Qt.rgba(r, g, b, 1.0);
                            if (root.getContrast(candidate, newSurface) >= 4.5) {
                                newTextMuted = candidate;
                                break;
                            }
                        }
                    }
                    if (root.getContrast(newTextMuted, newSurface) < 4.5) {
                        newTextMuted = newTextSec;
                    }
                }

                // WCAG AA Verification: onAccent requires >= 4.5:1 against accent
                if (root.getContrast(newOnAccent, newAccent) < 4.5) {
                    newOnAccent = root.getWcagLuminance(newAccent) > 0.5 ? Qt.color("#111111") : Qt.color("#fcfcfc");
                }

                // Atomically update state only after all validations pass
                root.bgCanvas = newBg;
                root.surfaceLow = newSurfaceLow;
                root.surfaceContainer = newSurface;
                root.surfaceHigh = newSurfaceHigh;
                root.textPrimary = newTextPrimary;
                root.textSecondary = newTextSec;
                root.textMuted = newTextMuted;
                root.accent = newAccent;
                root.accentContainer = newAccentContainer;
                root.onAccent = newOnAccent;
                root.dynamicSchemeActive = true;
            } catch (err) {
                console.warn("[Rice Theme] scheme.json parse error:", err);
                root.resetToFallbacks();
            }
        }

        onLoadFailed: {
            root.resetToFallbacks();
        }
    }
}
