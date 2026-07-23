#pragma once

#include <cmath>
#include <cstdint>
#include <sol/sol.hpp>
#include <string>
#include <vector>

namespace Hyprtoolkit::Lua {

inline std::vector<uint8_t> luaToBytes(const sol::object& object) {
    if (object.is<std::string>()) {
        const std::string data = object.as<std::string>();
        return {data.begin(), data.end()};
    }

    if (!object.is<sol::table>())
        throw sol::error("ImageBuilder:data expects a binary string or a dense byte array");

    const sol::table table = object.as<sol::table>();
    const size_t length = table.size();
    size_t entryCount   = 0;
    for (const auto& [key, value] : table) {
        (void)value;
        if (!key.is<double>())
            throw sol::error("ImageBuilder:data expects a dense byte array with integer keys starting at 1");

        const double index = key.as<double>();
        if (!std::isfinite(index) || std::floor(index) != index || index < 1 || index > static_cast<double>(length))
            throw sol::error("ImageBuilder:data expects a dense byte array with integer keys starting at 1");
        ++entryCount;
    }
    if (entryCount != length)
        throw sol::error("ImageBuilder:data expects a dense byte array with no missing entries");

    std::vector<uint8_t> bytes;
    bytes.reserve(length);
    for (size_t index = 1; index <= length; ++index) {
        const sol::object item = table[index];
        if (!item.is<double>())
            throw sol::error("ImageBuilder:data byte array entries must be numbers");

        const double value = item.as<double>();
        if (!std::isfinite(value) || std::floor(value) != value || value < 0 || value > 255)
            throw sol::error("ImageBuilder:data byte array entries must be integers from 0 through 255");

        bytes.push_back(static_cast<uint8_t>(value));
    }
    return bytes;
}

} // namespace Hyprtoolkit::Lua
