import { BrowserRouter, Routes, Route } from 'react-router-dom'
import React from 'react'
import DashboardScreen from './screens/DashboardScreen'
import RoomScreen from './screens/RoomScreen'

import ResearchReportScreen from './screens/ResearchReportScreen'

function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen bg-background text-text flex flex-col">
        <Routes>
          <Route path="/" element={<DashboardScreen />} />
          <Route path="/room/:roomId" element={<RoomScreen />} />
          <Route path="/report/:roomId" element={<ResearchReportScreen />} />
        </Routes>
      </div>
    </BrowserRouter>
  )
}

export default App
