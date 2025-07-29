import { useEffect, useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Clock, Users, Target, MapPin, Zap, Shield, Heart } from "lucide-react"
import { getGameplayInfo, getMapInfo } from "@/api/gameplay"
import { toast } from "@/hooks/useToast"

export function Gameplay() {
  const [gameplayInfo, setGameplayInfo] = useState<any>(null)
  const [mapInfo, setMapInfo] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [gameplayData, mapData] = await Promise.all([
          getGameplayInfo(),
          getMapInfo()
        ])
        setGameplayInfo(gameplayData)
        setMapInfo(mapData)
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
        <div className="grid gap-6 md:grid-cols-2">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-64 bg-white/10 rounded-lg"></div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold bg-gradient-to-r from-white to-white/70 bg-clip-text text-transparent">
          Gameplay
        </h1>
        <p className="text-white/60 mt-1">
          Master the mechanics and dominate the battlefield
        </p>
      </div>

      <Tabs defaultValue="overview" className="w-full">
        <TabsList className="grid w-full grid-cols-4 bg-white/5 border-white/10">
          <TabsTrigger value="overview" className="text-white data-[state=active]:bg-white/10">
            Overview
          </TabsTrigger>
          <TabsTrigger value="phases" className="text-white data-[state=active]:bg-white/10">
            Game Phases
          </TabsTrigger>
          <TabsTrigger value="mechanics" className="text-white data-[state=active]:bg-white/10">
            Mechanics
          </TabsTrigger>
          <TabsTrigger value="map" className="text-white data-[state=active]:bg-white/10">
            Map Info
          </TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2">
            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Clock className="h-5 w-5 text-purple-400" />
                  Round Structure
                </CardTitle>
                <CardDescription className="text-white/60">
                  Understanding the game flow
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {gameplayInfo?.roundStructure?.map((phase: any, index: number) => (
                  <div key={index} className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-white font-medium">{phase.name}</span>
                      <Badge variant="outline" className="border-purple-400/30 text-purple-400">
                        {phase.duration}
                      </Badge>
                    </div>
                    <p className="text-sm text-white/70">{phase.description}</p>
                    {index < gameplayInfo.roundStructure.length - 1 && (
                      <div className="h-px bg-white/10 mt-3" />
                    )}
                  </div>
                ))}
              </CardContent>
            </Card>

            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Target className="h-5 w-5 text-red-400" />
                  Victory Conditions
                </CardTitle>
                <CardDescription className="text-white/60">
                  How to achieve victory
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-3">
                  <div className="p-3 rounded-lg bg-blue-500/10 border border-blue-500/20">
                    <h4 className="text-blue-400 font-medium mb-2">Survivor Victory</h4>
                    <p className="text-sm text-white/70">
                      {gameplayInfo?.victoryConditions?.survivors}
                    </p>
                  </div>
                  <div className="p-3 rounded-lg bg-red-500/10 border border-red-500/20">
                    <h4 className="text-red-400 font-medium mb-2">The Flesh Victory</h4>
                    <p className="text-sm text-white/70">
                      {gameplayInfo?.victoryConditions?.killer}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Users className="h-5 w-5 text-green-400" />
                  Player Requirements
                </CardTitle>
                <CardDescription className="text-white/60">
                  Server and lobby requirements
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-white/70">Minimum Players</span>
                  <span className="text-white font-medium">{gameplayInfo?.playerRequirements?.minimum}</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-white/70">Maximum Players</span>
                  <span className="text-white font-medium">{gameplayInfo?.playerRequirements?.maximum}</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-white/70">Lobby Timer</span>
                  <span className="text-white font-medium">{gameplayInfo?.playerRequirements?.lobbyTimer}</span>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Zap className="h-5 w-5 text-yellow-400" />
                  Core Mechanics
                </CardTitle>
                <CardDescription className="text-white/60">
                  Essential gameplay elements
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                {gameplayInfo?.coreMechanics?.map((mechanic: string, index: number) => (
                  <div key={index} className="flex items-center gap-2 text-sm">
                    <div className="w-2 h-2 bg-yellow-400 rounded-full" />
                    <span className="text-white/80">{mechanic}</span>
                  </div>
                ))}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="phases" className="space-y-6">
          <div className="space-y-6">
            {gameplayInfo?.detailedPhases?.map((phase: any, index: number) => (
              <Card key={index} className="bg-white/5 backdrop-blur-sm border-white/10">
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-white flex items-center gap-2">
                      <div className={`w-3 h-3 rounded-full ${phase.color}`} />
                      {phase.name}
                    </CardTitle>
                    <Badge variant="outline" className="border-white/20 text-white/70">
                      {phase.duration}
                    </Badge>
                  </div>
                  <CardDescription className="text-white/60">
                    {phase.description}
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <h4 className="text-white font-medium">Key Activities</h4>
                      <ul className="space-y-1">
                        {phase.activities?.map((activity: string, actIndex: number) => (
                          <li key={actIndex} className="text-sm text-white/70 flex items-center gap-2">
                            <div className="w-1 h-1 bg-white/40 rounded-full" />
                            {activity}
                          </li>
                        ))}
                      </ul>
                    </div>
                    <div className="space-y-2">
                      <h4 className="text-white font-medium">Player Actions</h4>
                      <ul className="space-y-1">
                        {phase.playerActions?.map((action: string, actionIndex: number) => (
                          <li key={actionIndex} className="text-sm text-white/70 flex items-center gap-2">
                            <div className="w-1 h-1 bg-white/40 rounded-full" />
                            {action}
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="mechanics" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2">
            {gameplayInfo?.mechanics?.map((mechanic: any, index: number) => (
              <Card key={index} className="bg-white/5 backdrop-blur-sm border-white/10">
                <CardHeader>
                  <CardTitle className="text-white flex items-center gap-2">
                    {mechanic.type === 'combat' && <Target className="h-5 w-5 text-red-400" />}
                    {mechanic.type === 'movement' && <Zap className="h-5 w-5 text-yellow-400" />}
                    {mechanic.type === 'survival' && <Heart className="h-5 w-5 text-green-400" />}
                    {mechanic.type === 'utility' && <Shield className="h-5 w-5 text-blue-400" />}
                    {mechanic.name}
                  </CardTitle>
                  <CardDescription className="text-white/60">
                    {mechanic.description}
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-3">
                  {mechanic.details?.map((detail: any, detailIndex: number) => (
                    <div key={detailIndex} className="space-y-1">
                      <div className="flex items-center justify-between">
                        <span className="text-sm font-medium text-white/80">{detail.aspect}</span>
                        {detail.value && (
                          <Badge variant="outline" className="text-xs border-white/20 text-white/70">
                            {detail.value}
                          </Badge>
                        )}
                      </div>
                      <p className="text-xs text-white/60">{detail.explanation}</p>
                    </div>
                  ))}
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="map" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2">
            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <MapPin className="h-5 w-5 text-purple-400" />
                  Map Overview
                </CardTitle>
                <CardDescription className="text-white/60">
                  {mapInfo?.name} - {mapInfo?.description}
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-3">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-white/70">Map Name</span>
                    <span className="text-white font-medium">{mapInfo?.name}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-white/70">Game Area</span>
                    <span className="text-white font-medium">{mapInfo?.gameArea}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-white/70">Lobby Area</span>
                    <span className="text-white font-medium">{mapInfo?.lobbyArea}</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-white/5 backdrop-blur-sm border-white/10">
              <CardHeader>
                <CardTitle className="text-white">Spawn Locations</CardTitle>
                <CardDescription className="text-white/60">
                  Where players start each round
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {mapInfo?.spawnLocations?.map((location: any, index: number) => (
                  <div key={index} className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-white font-medium">{location.name}</span>
                      <Badge
                        variant={location.type === 'survivor' ? 'default' : 'destructive'}
                        className={location.type === 'survivor' ? 'bg-blue-500/20 text-blue-400' : 'bg-red-500/20 text-red-400'}
                      >
                        {location.type}
                      </Badge>
                    </div>
                    <p className="text-sm text-white/70">{location.description}</p>
                  </div>
                ))}
              </CardContent>
            </Card>

            <Card className="bg-white/5 backdrop-blur-sm border-white/10 md:col-span-2">
              <CardHeader>
                <CardTitle className="text-white">Strategic Locations</CardTitle>
                <CardDescription className="text-white/60">
                  Important areas and their tactical significance
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid md:grid-cols-2 gap-4">
                  {mapInfo?.strategicLocations?.map((location: any, index: number) => (
                    <div key={index} className="p-3 rounded-lg bg-white/5 border border-white/10">
                      <div className="flex items-center justify-between mb-2">
                        <h4 className="text-white font-medium">{location.name}</h4>
                        <Badge variant="outline" className="text-xs border-white/20 text-white/70">
                          {location.importance}
                        </Badge>
                      </div>
                      <p className="text-sm text-white/70 mb-2">{location.description}</p>
                      <div className="flex flex-wrap gap-1">
                        {location.features?.map((feature: string, featureIndex: number) => (
                          <Badge key={featureIndex} variant="outline" className="text-xs border-purple-400/30 text-purple-400">
                            {feature}
                          </Badge>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}