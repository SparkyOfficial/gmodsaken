import { useEffect, useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { BarChart3, TrendingUp, Users, Target, Clock, Trophy, Zap, Activity } from "lucide-react"
import { getStatistics, getLeaderboard, getRecentMatches } from "@/api/statistics"
import { toast } from "@/hooks/useToast"

export function Statistics() {
  const [statistics, setStatistics] = useState<any>(null)
  const [leaderboard, setLeaderboard] = useState<any>(null)
  const [recentMatches, setRecentMatches] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [statsData, leaderboardData, matchesData] = await Promise.all([
          getStatistics(),
          getLeaderboard(),
          getRecentMatches()
        ])
        setStatistics(statsData)
        setLeaderboard(leaderboardData)
        setRecentMatches(matchesData)
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
          {[...Array(8)].map((_, i) => (
            <div key={i} className="h-32 bg-white/10 rounded-lg"></div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold bg-gradient-to-r from-white to-white/70 bg-clip-text text-transparent">
          Statistics
        </h1>
        <p className="text-white/60 mt-1">
          Game statistics and leaderboards
        </p>
      </div>

      <Tabs defaultValue="overview" className="w-full">
        <TabsList className="grid w-full grid-cols-4 bg-white/5 border-white/10">
          <TabsTrigger value="overview" className="text-white data-[state=active]:bg-white/10">
            Overview
          </TabsTrigger>
          <TabsTrigger value="leaderboard" className="text-white data-[state=active]:bg-white/10">
            Leaderboard
          </TabsTrigger>
          <TabsTrigger value="matches" className="text-white data-[state=active]:bg-white/10">
            Recent Matches
          </TabsTrigger>
          <TabsTrigger value="characters" className="text-white data-[state=active]:bg-white/10">
            Character Stats
          </TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium text-white/70">Total Rounds</CardTitle>
                <BarChart3 className="h-4 w-4 text-purple-400" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-white">{statistics?.overview?.totalRounds || 0}</div>
                <p className="text-xs text-purple-400">
                  +{statistics?.overview?.roundsToday || 0} today
                </p>
              </CardContent>
            </Card>

            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium text-white/70">Survivor Win Rate</CardTitle>
                <Users className="h-4 w-4 text-blue-400" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-white">{statistics?.overview?.survivorWinRate || 0}%</div>
                <Progress value={statistics?.overview?.survivorWinRate || 0} className="h-1 mt-2" />
              </CardContent>
            </Card>

            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium text-white/70">Killer Win Rate</CardTitle>
                <Target className="h-4 w-4 text-red-400" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-white">{statistics?.overview?.killerWinRate || 0}%</div>
                <Progress value={statistics?.overview?.killerWinRate || 0} className="h-1 mt-2" />
              </CardContent>
            </Card>

            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium text-white/70">Avg Round Time</CardTitle>
                <Clock className="h-4 w-4 text-yellow-400" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-white">{statistics?.overview?.avgRoundTime || "0:00"}</div>
                <p className="text-xs text-yellow-400">
                  {statistics?.overview?.trend || "stable"}
                </p>
              </CardContent>
            </Card>
          </div>

          <div className="grid gap-6 md:grid-cols-2">
            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <TrendingUp className="h-5 w-5 text-green-400" />
                  Win Rate Trends
                </CardTitle>
                <CardDescription className="text-white/60">
                  Last 30 days performance
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {statistics?.trends?.map((trend: any, index: number) => (
                  <div key={index} className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-white/70">{trend.period}</span>
                      <div className="flex items-center gap-2">
                        <Badge
                          variant={trend.change > 0 ? 'default' : 'destructive'}
                          className={trend.change > 0 ? 'bg-green-500/20 text-green-400' : 'bg-red-500/20 text-red-400'}
                        >
                          {trend.change > 0 ? '+' : ''}{trend.change}%
                        </Badge>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-sm">
                      <div className="flex justify-between">
                        <span className="text-blue-400">Survivors:</span>
                        <span className="text-white">{trend.survivorWinRate}%</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-red-400">Killer:</span>
                        <span className="text-white">{trend.killerWinRate}%</span>
                      </div>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>

            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Activity className="h-5 w-5 text-purple-400" />
                  Server Activity
                </CardTitle>
                <CardDescription className="text-white/60">
                  Peak hours and player activity
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {statistics?.activity?.map((activity: any, index: number) => (
                  <div key={index} className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-white/70">{activity.timeRange}</span>
                      <span className="text-white font-medium">{activity.avgPlayers} players</span>
                    </div>
                    <Progress value={activity.activityLevel} className="h-2" />
                    <div className="flex justify-between text-xs text-white/50">
                      <span>Peak: {activity.peakPlayers}</span>
                      <span>{activity.roundsPlayed} rounds</span>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="leaderboard" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2">
            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Trophy className="h-5 w-5 text-yellow-400" />
                  Top Survivors
                </CardTitle>
                <CardDescription className="text-white/60">
                  Highest survival rates
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {leaderboard?.survivors?.map((player: any, index: number) => (
                  <div key={index} className="flex items-center justify-between p-3 rounded-lg bg-white/5 border border-white/10">
                    <div className="flex items-center gap-3">
                      <div className={`w-6 h-6 rounded-full flex items-center justify-center text-white text-xs font-bold ${
                        index === 0 ? 'bg-yellow-500' : index === 1 ? 'bg-gray-400' : index === 2 ? 'bg-amber-600' : 'bg-white/20'
                      }`}>
                        {index + 1}
                      </div>
                      <span className="text-white font-medium">{player.name}</span>
                    </div>
                    <div className="text-right">
                      <div className="text-white font-medium">{player.winRate}%</div>
                      <div className="text-xs text-white/50">{player.roundsPlayed} rounds</div>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>

            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Target className="h-5 w-5 text-red-400" />
                  Top Killers
                </CardTitle>
                <CardDescription className="text-white/60">
                  Most effective killers
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {leaderboard?.killers?.map((player: any, index: number) => (
                  <div key={index} className="flex items-center justify-between p-3 rounded-lg bg-white/5 border border-white/10">
                    <div className="flex items-center gap-3">
                      <div className={`w-6 h-6 rounded-full flex items-center justify-center text-white text-xs font-bold ${
                        index === 0 ? 'bg-yellow-500' : index === 1 ? 'bg-gray-400' : index === 2 ? 'bg-amber-600' : 'bg-white/20'
                      }`}>
                        {index + 1}
                      </div>
                      <span className="text-white font-medium">{player.name}</span>
                    </div>
                    <div className="text-right">
                      <div className="text-white font-medium">{player.winRate}%</div>
                      <div className="text-xs text-white/50">{player.roundsPlayed} rounds</div>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="matches" className="space-y-6">
          <Card className="bg-white/5 backdrop-blur-sm border-white/10">
            <CardHeader>
              <CardTitle className="text-white">Recent Matches</CardTitle>
              <CardDescription className="text-white/60">
                Last 20 completed rounds
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {recentMatches?.matches?.map((match: any, index: number) => (
                <div key={index} className="p-4 rounded-lg bg-white/5 border border-white/10">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-3">
                      <Badge
                        variant={match.winner === 'survivors' ? 'default' : 'destructive'}
                        className={match.winner === 'survivors' ? 'bg-blue-500/20 text-blue-400' : 'bg-red-500/20 text-red-400'}
                      >
                        {match.winner === 'survivors' ? 'Survivors Won' : 'The Flesh Won'}
                      </Badge>
                      <span className="text-white/70 text-sm">{match.duration}</span>
                    </div>
                    <span className="text-white/50 text-sm">{match.timeAgo}</span>
                  </div>
                  <div className="grid md:grid-cols-2 gap-4">
                    <div>
                      <h4 className="text-white font-medium mb-2">Survivors ({match.survivors.length})</h4>
                      <div className="space-y-1">
                        {match.survivors.map((survivor: any, survivorIndex: number) => (
                          <div key={survivorIndex} className="flex items-center justify-between text-sm">
                            <span className="text-white/70">{survivor.name}</span>
                            <Badge variant="outline" className="text-xs border-blue-400/30 text-blue-400">
                              {survivor.character}
                            </Badge>
                          </div>
                        ))}
                      </div>
                    </div>
                    <div>
                      <h4 className="text-white font-medium mb-2">The Flesh</h4>
                      <div className="flex items-center justify-between text-sm">
                        <span className="text-white/70">{match.killer.name}</span>
                        <Badge variant="destructive" className="text-xs bg-red-500/20 text-red-400">
                          {match.killer.kills} kills
                        </Badge>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="characters" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {statistics?.characters?.map((character: any, index: number) => (
              <Card key={index} className="bg-white/5 backdrop-blur-sm border-white/10">
                <CardHeader>
                  <CardTitle className="text-white">{character.name}</CardTitle>
                  <CardDescription className="text-white/60">
                    {character.role} - {character.timesPlayed} times played
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-white/70">Win Rate</span>
                      <span className="text-white font-medium">{character.winRate}%</span>
                    </div>
                    <Progress value={character.winRate} className="h-2" />
                  </div>

                  <div className="space-y-2">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-white/70">Avg Survival Time</span>
                      <span className="text-white">{character.avgSurvivalTime}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-white/70">Pick Rate</span>
                      <span className="text-white">{character.pickRate}%</span>
                    </div>
                  </div>

                  <div className="pt-2 border-t border-white/10">
                    <div className="flex items-center justify-between">
                      <span className="text-white/70 text-sm">Popularity</span>
                      <Badge
                        variant="outline"
                        className={
                          character.popularity === 'High'
                            ? 'border-green-400/30 text-green-400'
                            : character.popularity === 'Medium'
                            ? 'border-yellow-400/30 text-yellow-400'
                            : 'border-red-400/30 text-red-400'
                        }
                      >
                        {character.popularity}
                      </Badge>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}