import { useEffect, useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Progress } from "@/components/ui/progress"
import { Users, Clock, Trophy, Zap, Play, Eye, Target } from "lucide-react"
import { getGameStats, getCurrentMatch } from "@/api/game"
import { toast } from "@/hooks/useToast"

export function Home() {
  const [gameStats, setGameStats] = useState<any>(null)
  const [currentMatch, setCurrentMatch] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [statsData, matchData] = await Promise.all([
          getGameStats(),
          getCurrentMatch()
        ])
        setGameStats(statsData)
        setCurrentMatch(matchData)
      } catch (error: any) {
        toast({
          title: "Error",
          description: error.message,
          variant: "destructive",
        })
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [])

  if (loading) {
    return (
      <div className="space-y-6 animate-pulse">
        <div className="h-8 bg-white/10 rounded w-1/3"></div>
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-32 bg-white/10 rounded-lg"></div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold bg-gradient-to-r from-white to-white/70 bg-clip-text text-transparent">
            Dashboard
          </h1>
          <p className="text-white/60 mt-1">
            Welcome to GModsaken - Survival Horror Gamemode
          </p>
        </div>
        <Button className="bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 text-white">
          <Play className="h-4 w-4 mr-2" />
          Join Server
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <Card className="bg-white/5 backdrop-blur-sm border-white/10 hover:bg-white/10 transition-all duration-300">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-white/70">Online Players</CardTitle>
            <Users className="h-4 w-4 text-green-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-white">{gameStats?.onlinePlayers || 0}</div>
            <p className="text-xs text-green-400">
              +{gameStats?.newPlayersToday || 0} today
            </p>
          </CardContent>
        </Card>

        <Card className="bg-white/5 backdrop-blur-sm border-white/10 hover:bg-white/10 transition-all duration-300">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-white/70">Active Rounds</CardTitle>
            <Clock className="h-4 w-4 text-blue-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-white">{gameStats?.activeRounds || 0}</div>
            <p className="text-xs text-blue-400">
              Avg: {gameStats?.avgRoundTime || "0:00"}
            </p>
          </CardContent>
        </Card>

        <Card className="bg-white/5 backdrop-blur-sm border-white/10 hover:bg-white/10 transition-all duration-300">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-white/70">Win Rate</CardTitle>
            <Trophy className="h-4 w-4 text-yellow-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-white">{gameStats?.survivorWinRate || 0}%</div>
            <p className="text-xs text-yellow-400">
              Survivors vs The Flesh
            </p>
          </CardContent>
        </Card>

        <Card className="bg-white/5 backdrop-blur-sm border-white/10 hover:bg-white/10 transition-all duration-300">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-white/70">Server Status</CardTitle>
            <Zap className="h-4 w-4 text-purple-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-white">Stable</div>
            <p className="text-xs text-purple-400">
              Uptime: {gameStats?.uptime || "99.9%"}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Current Match */}
      {currentMatch && (
        <Card className="bg-white/5 backdrop-blur-sm border-white/10">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <Eye className="h-5 w-5 text-red-400" />
              Current Match - Round {currentMatch.roundNumber}
            </CardTitle>
            <CardDescription className="text-white/60">
              {currentMatch.survivors.length} survivors vs The Flesh
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-white/70">Time Remaining</span>
              <Badge variant="destructive" className="bg-red-500/20 text-red-400">
                {currentMatch.timeRemaining}
              </Badge>
            </div>
            <Progress value={currentMatch.timeProgress} className="h-2" />
            
            <div className="grid md:grid-cols-2 gap-4 mt-4">
              <div className="space-y-2">
                <h4 className="font-medium text-white flex items-center gap-2">
                  <Users className="h-4 w-4 text-blue-400" />
                  Survivors ({currentMatch.survivors.length})
                </h4>
                <div className="space-y-1">
                  {currentMatch.survivors.map((survivor: any, index: number) => (
                    <div key={index} className="flex items-center justify-between text-sm">
                      <span className="text-white/70">{survivor.name}</span>
                      <Badge variant="outline" className="text-xs border-blue-400/30 text-blue-400">
                        {survivor.character}
                      </Badge>
                    </div>
                  ))}
                </div>
              </div>
              
              <div className="space-y-2">
                <h4 className="font-medium text-white flex items-center gap-2">
                  <Target className="h-4 w-4 text-red-400" />
                  The Flesh
                </h4>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-white/70">{currentMatch.killer.name}</span>
                  <Badge variant="destructive" className="text-xs bg-red-500/20 text-red-400">
                    {currentMatch.killer.health}% HP
                  </Badge>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Quick Info */}
      <div className="grid md:grid-cols-2 gap-6">
        <Card className="bg-white/5 backdrop-blur-sm border-white/10">
          <CardHeader>
            <CardTitle className="text-white">Game Overview</CardTitle>
            <CardDescription className="text-white/60">
              Round-based asymmetric survival horror
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex justify-between text-sm">
              <span className="text-white/70">Round Duration</span>
              <span className="text-white">6 minutes</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-white/70">Minimum Players</span>
              <span className="text-white">3 players</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-white/70">Map</span>
              <span className="text-white">gm_construct</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-white/70">Characters</span>
              <span className="text-white">7 available</span>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-white/5 backdrop-blur-sm border-white/10">
          <CardHeader>
            <CardTitle className="text-white">Victory Conditions</CardTitle>
            <CardDescription className="text-white/60">
              How to win as survivor or killer
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="space-y-1">
              <span className="text-sm font-medium text-blue-400">Survivors Win:</span>
              <p className="text-xs text-white/70">At least one survivor must survive for 6 minutes</p>
            </div>
            <div className="space-y-1">
              <span className="text-sm font-medium text-red-400">The Flesh Wins:</span>
              <p className="text-xs text-white/70">Eliminate all survivors before time expires</p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}