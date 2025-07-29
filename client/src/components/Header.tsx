import { Gamepad2, Users, Clock } from "lucide-react"
import { Button } from "./ui/button"
import { ThemeToggle } from "./ui/theme-toggle"
import { Badge } from "./ui/badge"

export function Header() {
  return (
    <header className="fixed top-0 z-50 w-full border-b border-white/10 bg-black/20 backdrop-blur-md supports-[backdrop-filter]:bg-black/20">
      <div className="flex h-16 items-center justify-between px-6">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <Gamepad2 className="h-8 w-8 text-purple-400" />
            <span className="text-xl font-bold bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
              GModsaken
            </span>
          </div>
          <Badge variant="secondary" className="bg-green-500/20 text-green-400 border-green-500/30">
            <div className="w-2 h-2 bg-green-400 rounded-full mr-2 animate-pulse" />
            Online
          </Badge>
        </div>
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2 text-sm text-white/70">
            <Users className="h-4 w-4" />
            <span>24 Players</span>
          </div>
          <div className="flex items-center gap-2 text-sm text-white/70">
            <Clock className="h-4 w-4" />
            <span>Round: 4:32</span>
          </div>
          <ThemeToggle />
        </div>
      </div>
    </header>
  )
}