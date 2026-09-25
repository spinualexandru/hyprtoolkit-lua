#include <hyprgraphics/color/Color.hpp>
#include <hyprtoolkit/core/Animation.hpp>
#include <hyprtoolkit/core/Input.hpp>
#include <hyprtoolkit/palette/Color.hpp>
#include <hyprtoolkit/palette/Gradient.hpp>
#include <hyprtoolkit/palette/Palette.hpp>
#include <hyprtoolkit/types/FontTypes.hpp>
#include <hyprtoolkit/types/SizeType.hpp>
#include <hyprutils/math/Box.hpp>
#include <hyprutils/math/Vector2D.hpp>
#include <sol/sol.hpp>

#include <algorithm>
#include <array>
#include <initializer_list>
#include <string_view>
#include <utility>

#include "../helpers/GradientFnAdapter.hpp"
#include "../helpers/SmartPtrAdapter.hpp"

using namespace Hyprutils::Math;
using namespace Hyprutils::Memory;

namespace Hyprtoolkit::Lua {

void registerVector2D(sol::table& module) {
    module.new_usertype<Vector2D>(
        "Vector2D", sol::constructors<Vector2D(), Vector2D(double, double)>(), "x", &Vector2D::x, "y", &Vector2D::y, "floor", &Vector2D::floor, "round", &Vector2D::round,
        "clamp", &Vector2D::clamp, "distance", &Vector2D::distance, sol::meta_function::addition,
        static_cast<Vector2D (Vector2D::*)(const Vector2D&) const>(&Vector2D::operator+), sol::meta_function::subtraction,
        static_cast<Vector2D (Vector2D::*)(const Vector2D&) const>(&Vector2D::operator-), sol::meta_function::multiplication,
        sol::overload([](const Vector2D& self, double scalar) { return self * scalar; }, static_cast<Vector2D (Vector2D::*)(const Vector2D&) const>(&Vector2D::operator*)),
        sol::meta_function::division, [](const Vector2D& self, double scalar) { return self / scalar; }, sol::meta_function::equal_to, &Vector2D::operator==,
        sol::meta_function::to_string, [](const Vector2D& vector) {
            return "Vector2D(" + std::to_string(vector.x) + ", " + std::to_string(vector.y) + ")";
        });
}

void registerBox(sol::table& module) {
    module.new_usertype<CBox>(
        "Box", sol::constructors<CBox(), CBox(double, double, double, double), CBox(const Vector2D&, const Vector2D&)>(), "x", &CBox::x, "y", &CBox::y, "w", &CBox::w, "h",
        &CBox::h, "pos", &CBox::pos, "size", &CBox::size, "middle", &CBox::middle, "containsPoint", &CBox::containsPoint, "empty", &CBox::empty, "intersection",
        &CBox::intersection, "expand", [](CBox& self, double amount) -> CBox& { return self.expand(amount); }, "round", &CBox::round, "translate", &CBox::translate, "scale",
        sol::overload([](CBox& self, double amount) -> CBox& { return self.scale(amount); }, static_cast<CBox& (CBox::*)(const Vector2D&)>(&CBox::scale)));
}

void registerColor(sol::table& module) {
    module.new_usertype<CHyprColor>(
        "Color", sol::no_constructor, "r", &CHyprColor::r, "g", &CHyprColor::g, "b", &CHyprColor::b, "a", &CHyprColor::a, "getAsHex", &CHyprColor::getAsHex, "asRGB",
        [](const CHyprColor& self, sol::this_state state) {
            const auto rgb = self.asRGB();
            return sol::state_view(state).create_table_with("r", rgb.r, "g", rgb.g, "b", rgb.b);
        },
        "asHSL",
        [](const CHyprColor& self, sol::this_state state) {
            const auto hsl = self.asHSL();
            return sol::state_view(state).create_table_with("h", hsl.h, "s", hsl.s, "l", hsl.l);
        },
        "asOkLab",
        [](const CHyprColor& self, sol::this_state state) {
            const auto lab = self.asOkLab();
            return sol::state_view(state).create_table_with("l", lab.l, "a", lab.a, "b", lab.b);
        },
        "brighten", &CHyprColor::brighten, "darken", &CHyprColor::darken, "mix", &CHyprColor::mix, "stripA", &CHyprColor::stripA, sol::meta_function::addition,
        [](const CHyprColor& left, const CHyprColor& right) { return CHyprColor{static_cast<float>(left.r + right.r), static_cast<float>(left.g + right.g),
                                                                              static_cast<float>(left.b + right.b), static_cast<float>(left.a + right.a)}; },
        sol::meta_function::subtraction,
        [](const CHyprColor& left, const CHyprColor& right) { return CHyprColor{static_cast<float>(left.r - right.r), static_cast<float>(left.g - right.g),
                                                                              static_cast<float>(left.b - right.b), static_cast<float>(left.a - right.a)}; },
        sol::meta_function::multiplication,
        [](const CHyprColor& self, float scalar) { return CHyprColor{static_cast<float>(self.r * scalar), static_cast<float>(self.g * scalar),
                                                                     static_cast<float>(self.b * scalar), static_cast<float>(self.a * scalar)}; },
        sol::meta_function::equal_to, &CHyprColor::operator==, sol::meta_function::to_string,
        [](const CHyprColor& color) {
            return "Color(" + std::to_string(color.r) + ", " + std::to_string(color.g) + ", " + std::to_string(color.b) + ", " + std::to_string(color.a) + ")";
        });

    sol::table color = module["Color"];
    color["new"]     = sol::overload(
        []() { return CHyprColor{}; }, [](float red, float green, float blue) { return CHyprColor{red, green, blue, 1.F}; },
        [](float red, float green, float blue, float alpha) { return CHyprColor{red, green, blue, alpha}; });
    color["fromHex"] = [](uint64_t value) { return CHyprColor{value}; };
}

void registerGradient(sol::table& module) {
    module.new_usertype<CGradientValueData>(
        "Gradient", sol::no_constructor, "colors",
        sol::property(
            [](const CGradientValueData& self, sol::this_state state) {
                sol::table colors = sol::state_view(state).create_table();
                for (size_t index = 0; index < self.m_vColors.size(); ++index)
                    colors[index + 1] = self.m_vColors[index];
                return colors;
            },
            [](CGradientValueData& self, const sol::table& colors) { self.m_vColors = luaToColors(colors); }),
        "angle", sol::property([](const CGradientValueData& self) { return self.m_fAngle; }, [](CGradientValueData& self, float angle) { self.m_fAngle = angle; }),
        sol::meta_function::equal_to, &CGradientValueData::operator==);

    sol::table gradient = module["Gradient"];
    gradient["new"]     = [](const sol::table& colors, sol::optional<float> angle) {
        CGradientValueData value;
        value.m_vColors = luaToColors(colors);
        value.m_fAngle  = angle.value_or(0.F);
        if (value.m_vColors.empty())
            throw sol::error("Gradient.new requires at least one Color");
        return value;
    };
    gradient["solid"] = [](const CHyprColor& color) { return CGradientValueData{color}; };
}

void registerDynamicSize(sol::table& module) {
    module.new_enum<CDynamicSize::eSizingType>(
        "SizeType", {{"ABSOLUTE", CDynamicSize::HT_SIZE_ABSOLUTE}, {"PERCENT", CDynamicSize::HT_SIZE_PERCENT}, {"AUTO", CDynamicSize::HT_SIZE_AUTO}});

    module.new_usertype<CDynamicSize>("DynamicSize", sol::constructors<CDynamicSize(CDynamicSize::eSizingType, CDynamicSize::eSizingType, const Vector2D&)>(), "calculate",
                                     [](const CDynamicSize& self, const Vector2D& elementSize, sol::optional<bool> grow) {
                                         return self.calculate(elementSize, grow.value_or(true));
                                     });

    sol::table size = module["DynamicSize"];
    size["absolute"] = [](double width, double height) {
        return CDynamicSize{CDynamicSize::HT_SIZE_ABSOLUTE, CDynamicSize::HT_SIZE_ABSOLUTE, {width, height}};
    };
    size["percent"] = [](double width, double height) {
        return CDynamicSize{CDynamicSize::HT_SIZE_PERCENT, CDynamicSize::HT_SIZE_PERCENT, {width, height}};
    };
    size["auto"] = []() {
        return CDynamicSize{CDynamicSize::HT_SIZE_AUTO, CDynamicSize::HT_SIZE_AUTO, {0, 0}};
    };
    size["mixed"] = [](CDynamicSize::eSizingType typeX, CDynamicSize::eSizingType typeY, double width, double height) {
        return CDynamicSize{typeX, typeY, {width, height}};
    };
}

void registerFontTypes(sol::table& module) {
    module.new_enum<CFontSize::eSizingBase>(
        "FontSizeBase",
        {{"H1", CFontSize::HT_FONT_H1}, {"H2", CFontSize::HT_FONT_H2}, {"H3", CFontSize::HT_FONT_H3}, {"TEXT", CFontSize::HT_FONT_TEXT}, {"SMALL", CFontSize::HT_FONT_SMALL},
         {"ABSOLUTE", CFontSize::HT_FONT_ABSOLUTE}});

    module.new_enum<eFontAlignment>("FontAlignment", {{"LEFT", HT_FONT_ALIGN_LEFT}, {"CENTER", HT_FONT_ALIGN_CENTER}, {"RIGHT", HT_FONT_ALIGN_RIGHT}});

    module.new_usertype<CFontSize>("FontSize", sol::no_constructor, "ptSize", &CFontSize::ptSize);
    sol::table fontSize = module["FontSize"];
    fontSize["new"] = sol::overload([](CFontSize::eSizingBase base) { return CFontSize{base}; },
                                    [](CFontSize::eSizingBase base, float multiplier) { return CFontSize{base, multiplier}; });
    fontSize["h1"]       = [](sol::optional<float> multiplier) { return CFontSize{CFontSize::HT_FONT_H1, multiplier.value_or(1.F)}; };
    fontSize["h2"]       = [](sol::optional<float> multiplier) { return CFontSize{CFontSize::HT_FONT_H2, multiplier.value_or(1.F)}; };
    fontSize["h3"]       = [](sol::optional<float> multiplier) { return CFontSize{CFontSize::HT_FONT_H3, multiplier.value_or(1.F)}; };
    fontSize["text"]     = [](sol::optional<float> multiplier) { return CFontSize{CFontSize::HT_FONT_TEXT, multiplier.value_or(1.F)}; };
    fontSize["small"]    = [](sol::optional<float> multiplier) { return CFontSize{CFontSize::HT_FONT_SMALL, multiplier.value_or(1.F)}; };
    fontSize["absolute"] = [](float points) { return CFontSize{CFontSize::HT_FONT_ABSOLUTE, points}; };
}

void registerInputTypes(sol::table& module) {
    module.new_enum<Input::eMouseButton>(
        "MouseButton", {{"UNKNOWN", Input::MOUSE_BUTTON_UNKNOWN}, {"LEFT", Input::MOUSE_BUTTON_LEFT}, {"RIGHT", Input::MOUSE_BUTTON_RIGHT}, {"MIDDLE", Input::MOUSE_BUTTON_MIDDLE}});
    module.new_enum<Input::eAxisAxis>("Axis", {{"HORIZONTAL", Input::AXIS_AXIS_HORIZONTAL}, {"VERTICAL", Input::AXIS_AXIS_VERTICAL}});
    module.new_enum<Input::eKeyboardModifier>(
        "KeyboardModifier",
        {{"SHIFT", Input::HT_MODIFIER_SHIFT}, {"CAPS", Input::HT_MODIFIER_CAPS}, {"CTRL", Input::HT_MODIFIER_CTRL}, {"ALT", Input::HT_MODIFIER_ALT},
         {"MOD2", Input::HT_MODIFIER_MOD2}, {"MOD3", Input::HT_MODIFIER_MOD3}, {"META", Input::HT_MODIFIER_META}, {"MOD5", Input::HT_MODIFIER_MOD5},
         {"CTRL_SHIFT", Input::HT_MODIFIER_CTRL_SHIFT}});

    module.new_usertype<Input::SKeyboardKeyEvent>(
        "KeyboardKeyEvent", sol::no_constructor, "xkbKeysym", &Input::SKeyboardKeyEvent::xkbKeysym, "down", &Input::SKeyboardKeyEvent::down, "repeat",
        &Input::SKeyboardKeyEvent::repeat, "utf8", &Input::SKeyboardKeyEvent::utf8, "modMask", &Input::SKeyboardKeyEvent::modMask, "hasModifier",
        [](const Input::SKeyboardKeyEvent& event, Input::eKeyboardModifier modifier) {
            return (event.modMask & static_cast<uint32_t>(modifier)) != 0;
        });

    // Upstream's element-local `local` field is exposed as `position` because `local` is a Lua keyword.
    module.new_usertype<Input::STouchEvent>("TouchEvent", sol::no_constructor, "id", &Input::STouchEvent::id, "position", &Input::STouchEvent::local, "timeMs",
                                            &Input::STouchEvent::timeMs);
}

static void rejectUnknownFields(const sol::table& fields, std::initializer_list<std::string_view> known, std::string_view context) {
    for (const auto& [key, value] : fields) {
        if (key.get_type() != sol::type::string)
            throw sol::error(std::string{context} + " expects a table with string keys");
        if (std::ranges::find(known, key.as<std::string_view>()) == known.end())
            throw sol::error(std::string{context} + " received unknown field '" + key.as<std::string>() + "'");
    }
}

template <typename T>
static void readField(const sol::table& fields, const char* name, T& out, std::string_view context) {
    const sol::object value = fields[name];
    if (value.get_type() == sol::type::lua_nil)
        return;
    if (!value.is<T>())
        throw sol::error(std::string{context} + " field '" + name + "' has the wrong type");
    out = value.as<T>();
}

void registerAnimationTypes(sol::table& module) {
    module.new_usertype<SNoAnimation>("NoAnimation", sol::constructors<SNoAnimation()>(), sol::meta_function::equal_to, &SNoAnimation::operator==);

    module.new_usertype<SBezierAnimation>(
        "BezierAnimation", sol::no_constructor, "durationMs",
        sol::property([](const SBezierAnimation& self) { return self.duration.count(); },
                      [](SBezierAnimation& self, double durationMs) { self.duration = std::chrono::milliseconds{static_cast<int64_t>(durationMs)}; }),
        "control1", &SBezierAnimation::control1, "control2", &SBezierAnimation::control2, sol::meta_function::equal_to, &SBezierAnimation::operator==);
    sol::table bezier = module["BezierAnimation"];
    bezier["new"]     = [](sol::optional<sol::table> fields) {
        SBezierAnimation animation;
        if (!fields)
            return animation;

        rejectUnknownFields(*fields, {"durationMs", "control1", "control2"}, "BezierAnimation.new");
        double durationMs = static_cast<double>(animation.duration.count());
        readField(*fields, "durationMs", durationMs, "BezierAnimation.new");
        animation.duration = std::chrono::milliseconds{static_cast<int64_t>(durationMs)};
        readField(*fields, "control1", animation.control1, "BezierAnimation.new");
        readField(*fields, "control2", animation.control2, "BezierAnimation.new");
        return animation;
    };

    module.new_usertype<SSpringAnimation>(
        "SpringAnimation", sol::no_constructor, "stiffness", &SSpringAnimation::stiffness, "damping", &SSpringAnimation::damping, "mass", &SSpringAnimation::mass,
        "valueEpsilon", &SSpringAnimation::valueEpsilon, "velocityEpsilon", &SSpringAnimation::velocityEpsilon, sol::meta_function::equal_to,
        &SSpringAnimation::operator==);
    sol::table spring = module["SpringAnimation"];
    spring["new"]     = [](sol::optional<sol::table> fields) {
        SSpringAnimation animation;
        if (!fields)
            return animation;

        rejectUnknownFields(*fields, {"stiffness", "damping", "mass", "valueEpsilon", "velocityEpsilon"}, "SpringAnimation.new");
        readField(*fields, "stiffness", animation.stiffness, "SpringAnimation.new");
        readField(*fields, "damping", animation.damping, "SpringAnimation.new");
        readField(*fields, "mass", animation.mass, "SpringAnimation.new");
        readField(*fields, "valueEpsilon", animation.valueEpsilon, "SpringAnimation.new");
        readField(*fields, "velocityEpsilon", animation.velocityEpsilon, "SpringAnimation.new");
        return animation;
    };

    // Presets are upstream constants, so every lookup returns a fresh copy that callers can modify safely.
    static constexpr std::array<std::pair<std::string_view, SSpringAnimation>, 5> PRESETS = {{
        {"Slow", AnimationPresets::Slow},
        {"Medium", AnimationPresets::Medium},
        {"Fast", AnimationPresets::Fast},
        {"Snappy", AnimationPresets::Snappy},
        {"Bouncy", AnimationPresets::Bouncy},
    }};

    sol::state_view lua(module.lua_state());
    sol::table      presetsMeta            = lua.create_table();
    presetsMeta[sol::meta_function::index] = [](const sol::table&, std::string_view name) -> sol::optional<SSpringAnimation> {
        for (const auto& [presetName, preset] : PRESETS) {
            if (presetName == name)
                return preset;
        }
        return sol::nullopt;
    };
    presetsMeta[sol::meta_function::new_index] = [](const sol::table&, const sol::object&, const sol::object&) {
        throw sol::error("AnimationPresets is read-only");
    };

    sol::table presets          = lua.create_table();
    presets[sol::metatable_key] = presetsMeta;
    module["AnimationPresets"]  = presets;
}

void registerPalette(sol::table& module) {
#define PALETTE_COLOR_PROPERTY(luaName, field)                                                                                                                 \
    luaName, sol::property([](const CPalette& palette) { return palette.m_colors.field; }, [](CPalette& palette, const CHyprColor& color) { palette.m_colors.field = color; })
#define PALETTE_VAR_PROPERTY(luaName, field, type)                                                                                                              \
    luaName, sol::property([](const CPalette& palette) { return palette.m_vars.field; }, [](CPalette& palette, type value) { palette.m_vars.field = std::move(value); })

    module.new_usertype<CPalette>(
        "Palette", sol::no_constructor, "palette", &CPalette::palette, "emptyPalette", &CPalette::emptyPalette, PALETTE_COLOR_PROPERTY("background", background),
        PALETTE_COLOR_PROPERTY("text", text), PALETTE_COLOR_PROPERTY("base", base), PALETTE_COLOR_PROPERTY("alternateBase", alternateBase),
        PALETTE_COLOR_PROPERTY("brightText", brightText), PALETTE_COLOR_PROPERTY("linkText", linkText), PALETTE_COLOR_PROPERTY("accent", accent),
        PALETTE_COLOR_PROPERTY("accentSecondary", accentSecondary), PALETTE_VAR_PROPERTY("h1Size", h1Size, int), PALETTE_VAR_PROPERTY("h2Size", h2Size, int),
        PALETTE_VAR_PROPERTY("h3Size", h3Size, int), PALETTE_VAR_PROPERTY("fontSize", fontSize, int), PALETTE_VAR_PROPERTY("smallFontSize", smallFontSize, int),
        PALETTE_VAR_PROPERTY("iconTheme", iconTheme, std::string), PALETTE_VAR_PROPERTY("bigRounding", bigRounding, int),
        PALETTE_VAR_PROPERTY("smallRounding", smallRounding, int), PALETTE_VAR_PROPERTY("fontFamily", fontFamily, std::string),
        PALETTE_VAR_PROPERTY("fontFamilyMonospace", fontFamilyMonospace, std::string));

#undef PALETTE_VAR_PROPERTY
#undef PALETTE_COLOR_PROPERTY
}

void registerTypes(sol::table& module) {
    registerVector2D(module);
    registerBox(module);
    registerColor(module);
    registerGradient(module);
    registerDynamicSize(module);
    registerFontTypes(module);
    registerInputTypes(module);
    registerAnimationTypes(module);
    registerPalette(module);
}

} // namespace Hyprtoolkit::Lua
