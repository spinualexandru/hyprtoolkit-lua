#pragma once

#include <hyprutils/signal/Listener.hpp>

namespace Hyprtoolkit::Lua {

class CSignalConnection {
  public:
    explicit CSignalConnection(Hyprutils::Signal::CHyprSignalListener listener) : m_listener(std::move(listener)) {}

    bool connected() const {
        return static_cast<bool>(m_listener);
    }

    void disconnect() {
        m_listener.reset();
    }

  private:
    Hyprutils::Signal::CHyprSignalListener m_listener;
};

} // namespace Hyprtoolkit::Lua
