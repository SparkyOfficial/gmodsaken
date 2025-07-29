import { useEffect, useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Heart, Shield, Zap, Wrench, Phone, Crosshair, Axe } from "lucide-react"
import { getCharacters, getCharacterStats } from "@/api/characters"
import { toast } from "@/hooks/useToast"

export function Characters() {
  const [characters, setCharacters] = useState<any[]>([])
  const [characterStats, setCharacterStats] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [charactersData, statsData] = await Promise.all([
          getCharacters(),
          getCharacterStats()
        ])
        setCharacters(charactersData.characters)
        setCharacterStats(statsData)
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

  const getCharacterIcon = (characterType: string) => {
    switch (characterType) {
      case 'Gordon Freeman': return Heart
      case 'Rebel': return Crosshair
      case 'Medic': return Heart
      case 'Engineer': return Wrench
      case 'Security Guard': return Shield
      case 'Mayor': return Phone
      case 'The Flesh': return Axe
      default: return Heart
    }
  }

  const getCharacterColor = (role: string) => {
    return role === 'Killer' ? 'text-red-400' : 'text-blue-400'
  }

  if (loading) {
    return (
      <div className="space-y-6 animate-pulse">
        <div className="h-8 bg-white/10 rounded w-1/3"></div>
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="h-64 bg-white/10 rounded-lg"></div>
          ))}
        </div>
      </div>
    )
  }

  const survivors = characters.filter(char => char.role === 'Survivor')
  const killers = characters.filter(char => char.role === 'Killer')

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold bg-gradient-to-r from-white to-white/70 bg-clip-text text-transparent">
          Characters
        </h1>
        <p className="text-white/60 mt-1">
          Choose your role and master your abilities
        </p>
      </div>

      <Tabs defaultValue="all" className="w-full">
        <TabsList className="grid w-full grid-cols-3 bg-white/5 border-white/10">
          <TabsTrigger value="all" className="text-white data-[state=active]:bg-white/10">
            All Characters
          </TabsTrigger>
          <TabsTrigger value="survivors" className="text-blue-400 data-[state=active]:bg-blue-500/20">
            Survivors ({survivors.length})
          </TabsTrigger>
          <TabsTrigger value="killers" className="text-red-400 data-[state=active]:bg-red-500/20">
            Killers ({killers.length})
          </TabsTrigger>
        </TabsList>

        <TabsContent value="all" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {characters.map((character, index) => {
              const Icon = getCharacterIcon(character.name)
              return (
                <Card key={index} className="bg-white/5 backdrop-blur-sm border-white/10 hover:bg-white/10 transition-all duration-300 group">
                  <CardHeader>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className={`p-2 rounded-lg bg-gradient-to-r ${character.role === 'Killer' ? 'from-red-500/20 to-red-600/20' : 'from-blue-500/20 to-blue-600/20'}`}>
                          <Icon className={`h-6 w-6 ${getCharacterColor(character.role)}`} />
                        </div>
                        <div>
                          <CardTitle className="text-white text-lg">{character.name}</CardTitle>
                          <Badge variant={character.role === 'Killer' ? 'destructive' : 'default'}
                                 className={character.role === 'Killer' ? 'bg-red-500/20 text-red-400' : 'bg-blue-500/20 text-blue-400'}>
                            {character.role}
                          </Badge>
                        </div>
                      </div>
                    </div>
                    <CardDescription className="text-white/60">
                      {character.description}
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="space-y-3">
                      <div className="flex items-center justify-between text-sm">
                        <span className="flex items-center gap-2 text-white/70">
                          <Heart className="h-4 w-4 text-red-400" />
                          Health
                        </span>
                        <span className="text-white font-medium">{character.health}</span>
                      </div>

                      {character.armor > 0 && (
                        <div className="flex items-center justify-between text-sm">
                          <span className="flex items-center gap-2 text-white/70">
                            <Shield className="h-4 w-4 text-blue-400" />
                            Armor
                          </span>
                          <span className="text-white font-medium">{character.armor}</span>
                        </div>
                      )}
                    </div>

                    <div className="space-y-2">
                      <h4 className="text-sm font-medium text-white/80">Equipment</h4>
                      <div className="flex flex-wrap gap-1">
                        {character.equipment.map((item: string, itemIndex: number) => (
                          <Badge key={itemIndex} variant="outline"
                                 className="text-xs border-white/20 text-white/70">
                            {item}
                          </Badge>
                        ))}
                      </div>
                    </div>

                    <div className="space-y-2">
                      <h4 className="text-sm font-medium text-white/80">Abilities</h4>
                      <div className="space-y-1">
                        {character.abilities.map((ability: any, abilityIndex: number) => (
                          <div key={abilityIndex} className="text-xs">
                            <span className="text-white/80 font-medium">{ability.name}:</span>
                            <span className="text-white/60 ml-1">{ability.description}</span>
                          </div>
                        ))}
                      </div>
                    </div>

                    {characterStats && characterStats[character.name] && (
                      <div className="space-y-2">
                        <div className="flex justify-between text-xs">
                          <span className="text-white/70">Win Rate</span>
                          <span className="text-white">{characterStats[character.name].winRate}%</span>
                        </div>
                        <Progress value={characterStats[character.name].winRate} className="h-1" />
                      </div>
                    )}
                  </CardContent>
                </Card>
              )
            })}
          </div>
        </TabsContent>

        <TabsContent value="survivors" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {survivors.map((character, index) => {
              const Icon = getCharacterIcon(character.name)
              return (
                <Card key={index} className="bg-white/5 backdrop-blur-sm border-blue-500/20 hover:bg-white/10 transition-all duration-300">
                  <CardHeader>
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-gradient-to-r from-blue-500/20 to-blue-600/20">
                        <Icon className="h-6 w-6 text-blue-400" />
                      </div>
                      <div>
                        <CardTitle className="text-white text-lg">{character.name}</CardTitle>
                        <Badge className="bg-blue-500/20 text-blue-400">Survivor</Badge>
                      </div>
                    </div>
                    <CardDescription className="text-white/60">
                      {character.description}
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="space-y-3">
                      <div className="flex items-center justify-between text-sm">
                        <span className="flex items-center gap-2 text-white/70">
                          <Heart className="h-4 w-4 text-red-400" />
                          Health
                        </span>
                        <span className="text-white font-medium">{character.health}</span>
                      </div>

                      {character.armor > 0 && (
                        <div className="flex items-center justify-between text-sm">
                          <span className="flex items-center gap-2 text-white/70">
                            <Shield className="h-4 w-4 text-blue-400" />
                            Armor
                          </span>
                          <span className="text-white font-medium">{character.armor}</span>
                        </div>
                      )}
                    </div>

                    <div className="space-y-2">
                      <h4 className="text-sm font-medium text-white/80">Equipment</h4>
                      <div className="flex flex-wrap gap-1">
                        {character.equipment.map((item: string, itemIndex: number) => (
                          <Badge key={itemIndex} variant="outline"
                                 className="text-xs border-blue-400/30 text-blue-400">
                            {item}
                          </Badge>
                        ))}
                      </div>
                    </div>

                    <div className="space-y-2">
                      <h4 className="text-sm font-medium text-white/80">Abilities</h4>
                      <div className="space-y-1">
                        {character.abilities.map((ability: any, abilityIndex: number) => (
                          <div key={abilityIndex} className="text-xs">
                            <span className="text-blue-400 font-medium">{ability.name}:</span>
                            <span className="text-white/60 ml-1">{ability.description}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              )
            })}
          </div>
        </TabsContent>

        <TabsContent value="killers" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {killers.map((character, index) => {
              const Icon = getCharacterIcon(character.name)
              return (
                <Card key={index} className="bg-white/5 backdrop-blur-sm border-red-500/20 hover:bg-white/10 transition-all duration-300">
                  <CardHeader>
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-gradient-to-r from-red-500/20 to-red-600/20">
                        <Icon className="h-6 w-6 text-red-400" />
                      </div>
                      <div>
                        <CardTitle className="text-white text-lg">{character.name}</CardTitle>
                        <Badge variant="destructive" className="bg-red-500/20 text-red-400">Killer</Badge>
                      </div>
                    </div>
                    <CardDescription className="text-white/60">
                      {character.description}
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="space-y-3">
                      <div className="flex items-center justify-between text-sm">
                        <span className="flex items-center gap-2 text-white/70">
                          <Heart className="h-4 w-4 text-red-400" />
                          Health
                        </span>
                        <span className="text-white font-medium">{character.health}</span>
                      </div>
                    </div>

                    <div className="space-y-2">
                      <h4 className="text-sm font-medium text-white/80">Equipment</h4>
                      <div className="flex flex-wrap gap-1">
                        {character.equipment.map((item: string, itemIndex: number) => (
                          <Badge key={itemIndex} variant="outline"
                                 className="text-xs border-red-400/30 text-red-400">
                            {item}
                          </Badge>
                        ))}
                      </div>
                    </div>

                    <div className="space-y-2">
                      <h4 className="text-sm font-medium text-white/80">Abilities</h4>
                      <div className="space-y-1">
                        {character.abilities.map((ability: any, abilityIndex: number) => (
                          <div key={abilityIndex} className="text-xs">
                            <span className="text-red-400 font-medium">{ability.name}:</span>
                            <span className="text-white/60 ml-1">{ability.description}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              )
            })}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}