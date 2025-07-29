import { NavLink } from "react-router-dom"
import { Home, Users, Gamepad, BookOpen, BarChart3, Settings } from "lucide-react"
import { cn } from "@/lib/utils"

const navigation = [
  { name: 'Dashboard', href: '/', icon: Home },
  { name: 'Characters', href: '/characters', icon: Users },
  { name: 'Gameplay', href: '/gameplay', icon: Gamepad },
  { name: 'Rules', href: '/rules', icon: BookOpen },
  { name: 'Statistics', href: '/statistics', icon: BarChart3 },
]

export function Sidebar() {
  return (
    <div className="fixed inset-y-0 left-0 z-40 w-64 pt-16">
      <div className="h-full bg-black/20 backdrop-blur-md border-r border-white/10">
        <nav className="p-4 space-y-2">
          {navigation.map((item) => (
            <NavLink
              key={item.name}
              to={item.href}
              className={({ isActive }) =>
                cn(
                  "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-all duration-200",
                  "hover:bg-white/10 hover:text-white",
                  isActive
                    ? "bg-gradient-to-r from-purple-500/20 to-pink-500/20 text-white border border-purple-500/30"
                    : "text-white/70"
                )
              }
            >
              <item.icon className="h-5 w-5" />
              {item.name}
            </NavLink>
          ))}
        </nav>
      </div>
    </div>
  )
}