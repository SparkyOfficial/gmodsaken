import { BrowserRouter as Router, Routes, Route } from "react-router-dom"
import { ThemeProvider } from "./components/ui/theme-provider"
import { Toaster } from "./components/ui/toaster"
import { Layout } from "./components/Layout"
import { Home } from "./pages/Home"
import { Characters } from "./pages/Characters"
import { Gameplay } from "./pages/Gameplay"
import { Rules } from "./pages/Rules"
import { Statistics } from "./pages/Statistics"

function App() {
  return (
    <ThemeProvider defaultTheme="dark" storageKey="ui-theme">
      <Router>
        <Routes>
          <Route path="/" element={<Layout />}>
            <Route index element={<Home />} />
            <Route path="/characters" element={<Characters />} />
            <Route path="/gameplay" element={<Gameplay />} />
            <Route path="/rules" element={<Rules />} />
            <Route path="/statistics" element={<Statistics />} />
          </Route>
        </Routes>
      </Router>
      <Toaster />
    </ThemeProvider>
  )
}

export default App