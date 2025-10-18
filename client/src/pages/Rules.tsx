import { useEffect, useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { BookOpen, AlertTriangle, Info, Users, Target, Clock } from "lucide-react"
import { getRules, getServerRules } from "@/api/rules"
import { toast } from "@/hooks/useToast"

export function Rules() {
  const [gameRules, setGameRules] = useState<any>(null)
  const [serverRules, setServerRules] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [gameRulesData, serverRulesData] = await Promise.all([
          getRules(),
          getServerRules()
        ])
        setGameRules(gameRulesData)
        setServerRules(serverRulesData)
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
        <div className="grid gap-6">
          {[...Array(3)].map((_, i) => (
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
          Rules & Guidelines
        </h1>
        <p className="text-white/60 mt-1">
          Everything you need to know to play GModsaken
        </p>
      </div>

      <Tabs defaultValue="gameplay" className="w-full">
        <TabsList className="grid w-full grid-cols-3 bg-white/5 border-white/10">
          <TabsTrigger value="gameplay" className="text-white data-[state=active]:bg-white/10">
            Gameplay Rules
          </TabsTrigger>
          <TabsTrigger value="server" className="text-white data-[state=active]:bg-white/10">
            Server Rules
          </TabsTrigger>
          <TabsTrigger value="conduct" className="text-white data-[state=active]:bg-white/10">
            Code of Conduct
          </TabsTrigger>
        </TabsList>

        <TabsContent value="gameplay" className="space-y-6">
          <Alert className="bg-blue-500/10 border-blue-500/20">
            <Info className="h-4 w-4 text-blue-400" />
            <AlertTitle className="text-blue-400">Important</AlertTitle>
            <AlertDescription className="text-white/70">
              These rules are essential for fair and balanced gameplay. Violation may result in round penalties or kicks.
            </AlertDescription>
          </Alert>

          <div className="space-y-6">
            {gameRules?.categories?.map((category: any, index: number) => (
              <Card key={index} className="bg-white/5 backdrop-blur-sm border-white/10">
                <CardHeader>
                  <CardTitle className="text-white flex items-center gap-2">
                    {category.type === 'general' && <BookOpen className="h-5 w-5 text-purple-400" />}
                    {category.type === 'survivor' && <Users className="h-5 w-5 text-blue-400" />}
                    {category.type === 'killer' && <Target className="h-5 w-5 text-red-400" />}
                    {category.type === 'timing' && <Clock className="h-5 w-5 text-yellow-400" />}
                    {category.name}
                  </CardTitle>
                  <CardDescription className="text-white/60">
                    {category.description}
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-3">
                    {category.rules?.map((rule: any, ruleIndex: number) => (
                      <div key={ruleIndex} className="p-3 rounded-lg bg-white/5 border border-white/10">
                        <div className="flex items-start justify-between mb-2">
                          <h4 className="text-white font-medium">{rule.title}</h4>
                          <Badge 
                            variant={rule.severity === 'critical' ? 'destructive' : rule.severity === 'important' ? 'default' : 'outline'}
                            className={
                              rule.severity === 'critical' 
                                ? 'bg-red-500/20 text-red-400' 
                                : rule.severity === 'important'
                                ? 'bg-yellow-500/20 text-yellow-400'
                                : 'bg-gray-500/20 text-gray-400'
                            }
                          >
                            {rule.severity}
                          </Badge>
                        </div>
                        <p className="text-sm text-white/70 mb-2">{rule.description}</p>
                        {rule.examples && (
                          <div className="mt-2">
                            <span className="text-xs text-white/50 font-medium">Examples:</span>
                            <ul className="text-xs text-white/50 mt-1 space-y-1">
                              {rule.examples.map((example: string, exampleIndex: number) => (
                                <li key={exampleIndex} className="flex items-center gap-2">
                                  <div className="w-1 h-1 bg-white/30 rounded-full" />
                                  {example}
                                </li>
                              ))}
                            </ul>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="server" className="space-y-6">
          <Alert className="bg-red-500/10 border-red-500/20">
            <AlertTriangle className="h-4 w-4 text-red-400" />
            <AlertTitle className="text-red-400">Server Rules</AlertTitle>
            <AlertDescription className="text-white/70">
              Violation of server rules may result in temporary or permanent bans from the server.
            </AlertDescription>
          </Alert>

          <div className="space-y-6">
            {serverRules?.sections?.map((section: any, index: number) => (
              <Card key={index} className="bg-white/5 backdrop-blur-sm border-white/10">
                <CardHeader>
                  <CardTitle className="text-white">{section.title}</CardTitle>
                  <CardDescription className="text-white/60">
                    {section.description}
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-3">
                    {section.rules?.map((rule: any, ruleIndex: number) => (
                      <div key={ruleIndex} className="flex items-start gap-3 p-3 rounded-lg bg-white/5 border border-white/10">
                        <div className="w-6 h-6 rounded-full bg-gradient-to-r from-purple-500 to-pink-500 flex items-center justify-center text-white text-xs font-bold mt-0.5">
                          {ruleIndex + 1}
                        </div>
                        <div className="flex-1">
                          <h4 className="text-white font-medium mb-1">{rule.title}</h4>
                          <p className="text-sm text-white/70">{rule.description}</p>
                          {rule.penalty && (
                            <div className="mt-2">
                              <Badge variant="destructive" className="text-xs bg-red-500/20 text-red-400">
                                Penalty: {rule.penalty}
                              </Badge>
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="conduct" className="space-y-6">
          <Alert className="bg-green-500/10 border-green-500/20">
            <Info className="h-4 w-4 text-green-400" />
            <AlertTitle className="text-green-400">Community Guidelines</AlertTitle>
            <AlertDescription className="text-white/70">
              Help us maintain a positive and welcoming environment for all players.
            </AlertDescription>
          </Alert>

          <div className="grid gap-6 md:grid-cols-2">
            <Card className="bg-white/5 backdrop-blur-sm border-green-500/20">
              <CardHeader>
                <CardTitle className="text-green-400">Encouraged Behavior</CardTitle>
                <CardDescription className="text-white/60">
                  What we love to see in our community
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                {serverRules?.conduct?.encouraged?.map((item: any, index: number) => (
                  <div key={index} className="flex items-center gap-3">
                    <div className="w-2 h-2 bg-green-400 rounded-full" />
                    <div>
                      <span className="text-white font-medium">{item.title}</span>
                      <p className="text-sm text-white/70">{item.description}</p>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>

            <Card className="bg-white/5 backdrop-blur-sm border-red-500/20">
              <CardHeader>
                <CardTitle className="text-red-400">Prohibited Behavior</CardTitle>
                <CardDescription className="text-white/60">
                  Actions that will result in immediate punishment
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                {serverRules?.conduct?.prohibited?.map((item: any, index: number) => (
                  <div key={index} className="flex items-center gap-3">
                    <div className="w-2 h-2 bg-red-400 rounded-full" />
                    <div>
                      <span className="text-white font-medium">{item.title}</span>
                      <p className="text-sm text-white/70">{item.description}</p>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
          </div>

          <Card className="bg-white/5 backdrop-blur-sm border-white/10">
            <CardHeader>
              <CardTitle className="text-white">Reporting System</CardTitle>
              <CardDescription className="text-white/60">
                How to report rule violations and misconduct
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid md:grid-cols-3 gap-4">
                {serverRules?.reporting?.methods?.map((method: any, index: number) => (
                  <div key={index} className="p-3 rounded-lg bg-white/5 border border-white/10 text-center">
                    <h4 className="text-white font-medium mb-2">{method.name}</h4>
                    <p className="text-sm text-white/70 mb-2">{method.description}</p>
                    <Badge variant="outline" className="text-xs border-purple-400/30 text-purple-400">
                      {method.responseTime}
                    </Badge>
                  </div>
                ))}
              </div>
              <div className="p-4 rounded-lg bg-yellow-500/10 border border-yellow-500/20">
                <h4 className="text-yellow-400 font-medium mb-2">Important Note</h4>
                <p className="text-sm text-white/70">
                  {serverRules?.reporting?.note}
                </p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}