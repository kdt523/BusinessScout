import React, { useState, useEffect, useRef } from 'react';
import { useParams, useLocation, useNavigate } from 'react-router-dom';
import { MessageSquare, Map, FileText, Loader2, Info } from 'lucide-react';
import ResponsiveWebWrapper from '../components/ResponsiveWebWrapper';
import CollaborationChatbox from '../widgets/CollaborationChatbox';
import BandOrchestrationGraph from '../widgets/BandOrchestrationGraph';
import ScoutingResultsDashboard from '../widgets/ScoutingResultsDashboard';
import ApiService from '../services/apiService';

const AGENT_ORDER = ["Orchestrator", "Location Scout", "Competitor Analyst", "Business Planner"];

export default function RoomScreen() {
  const { roomId } = useParams();
  const location = useLocation();
  const navigate = useNavigate();
  
  const businessType = location.state?.businessType || 'Business';
  const city = location.state?.city || 'City';

  const [messages, setMessages] = useState([]);
  const [mapboxToken, setMapboxToken] = useState('');
  const [mapCenter, setMapCenter] = useState(null);
  const [zones, setZones] = useState([]);
  const [events, setEvents] = useState([]);
  
  const [isScouting, setIsScouting] = useState(true);
  const [currentAgent, setCurrentAgent] = useState("Orchestrator");
  const [statusMessage, setStatusMessage] = useState("Analyzing brief...");
  const [isComplete, setIsComplete] = useState(false);
  const [isDownloadingReport, setIsDownloadingReport] = useState(false);
  
  const [showGraph, setShowGraph] = useState(true);
  const [selectedTabIndex, setSelectedTabIndex] = useState(0);

  const hasNavigatedToReport = useRef(false);

  useEffect(() => {
    fetchMapboxToken();
    const cleanup = connectToStream();
    return cleanup;
  }, [roomId]);

  const fetchMapboxToken = async () => {
    const token = await ApiService.getMapboxAccessToken();
    setMapboxToken(token);
  };

  const connectToStream = () => {
    setSelectedTabIndex(0);
    setZones([]);
    setEvents([]);
    setIsScouting(true);
    setCurrentAgent("Orchestrator");
    setStatusMessage("Starting Multi-Agent session...");
    hasNavigatedToReport.current = false;

    const cleanup = ApiService.streamRoomMessages(
      roomId,
      (msg) => {
        setMessages(prev => [...prev, msg]);
        processMessageState(msg);
      },
      (err) => {
        console.error("Stream disconnected:", err);
      },
      () => {
        setIsScouting(false);
      }
    );

    return cleanup;
  };

  const processMessageState = (msg) => {
    if (msg.role === 'system') {
      const joinedAgent = extractJoinedAgent(msg.content);
      if (joinedAgent) {
        setCurrentAgent(joinedAgent);
        setStatusMessage(agentTaskLabel(joinedAgent));
        setIsScouting(true);
      }

      if (msg.content.includes("closed") || msg.content.includes("Complete")) {
        setIsComplete(true);
        setIsScouting(false);
        setStatusMessage("Analysis Complete");
      }
      return;
    }

    if (AGENT_ORDER.includes(msg.sender)) {
      setCurrentAgent(msg.sender);
    }

    if (msg.sender === 'Orchestrator') {
      setStatusMessage("Orchestrating agents...");
      setIsScouting(true);
    } else if (msg.sender === 'Location Scout') {
      setStatusMessage("Scouting geographic zones...");
      setIsScouting(true);
      if (msg.type === 'data') {
        if (msg.data.center) setMapCenter(msg.data.center);
        setZones(prev => {
          if (prev.length === 0 || !prev[0].opp_score) return msg.data.zones || [];
          return prev;
        });
        if (msg.data.events) setEvents(msg.data.events);
      }
    } else if (msg.sender === 'Competitor Analyst') {
      setStatusMessage("Analyzing market saturation...");
      setIsScouting(false);
      if (msg.type === 'data' && msg.data.enriched_zones) {
        setZones(msg.data.enriched_zones);
      }
    } else if (msg.sender === 'Business Planner') {
      setStatusMessage("Formulating business plan...");
      setIsScouting(false);
      if (msg.type === 'data') {
        setZones(prev => {
          if (prev.length === 0) {
            return msg.data.zones || msg.data.enriched_zones || [];
          }
          return prev;
        });
      }
    }
  };

  const extractJoinedAgent = (content) => {
    for (const agent of AGENT_ORDER) {
      if (content.includes(`@${agent} has joined`)) return agent;
    }
    return null;
  };

  const agentTaskLabel = (agent) => {
    switch (agent) {
      case "Orchestrator": return "Orchestrating agents...";
      case "Location Scout": return "Scouting zones with Bright Data context...";
      case "Competitor Analyst": return "Analyzing market saturation...";
      case "Business Planner": return "Writing final plan and PDF...";
      default: return "Working...";
    }
  };

  const downloadReport = async () => {
    if (isDownloadingReport) return;
    setIsDownloadingReport(true);

    try {
      let reportData = null;
      for (const msg of messages) {
        if (msg.sender === "Business Planner" && msg.type === "data") {
          reportData = msg.data;
          break;
        }
      }
      if (!reportData && zones.length > 0) {
        reportData = zones[0];
      }

      navigate(`/report/${roomId}`, {
        state: { businessType, city, reportData }
      });
      
    } catch (e) {
      alert(`Could not open report: ${e.message}`);
    } finally {
      setIsDownloadingReport(false);
    }
  };

  const handleSendMessage = async (content) => {
    return await ApiService.sendRoomMessage(roomId, 'User', 'user', content);
  };

  return (
    <ResponsiveWebWrapper>
      <div className="flex flex-col h-[100dvh] bg-[#FDFDFD]">
        {/* App Bar */}
        <div className="bg-white px-4 py-3 border-b border-[#111111]/20 flex items-center justify-between shrink-0">
          <div className="flex flex-col">
            <span className="text-black text-[15px] font-bold truncate max-w-[200px]">
              {businessType} • {city}
            </span>
            <div className="flex items-center mt-0.5">
              <div className={`w-1.5 h-1.5 rounded-full mr-1.5 ${isComplete ? 'bg-[#10B981]' : 'bg-[#FF187F]'}`} />
              <span className="text-gray-600 text-[10px] font-medium truncate max-w-[200px]">
                {isComplete ? "Consensus Reached" : `${currentAgent}: ${statusMessage}`}
              </span>
            </div>
          </div>
          {isComplete && (
            <button
              onClick={downloadReport}
              disabled={isDownloadingReport}
              className="flex items-center text-[#FF187F]"
            >
              {isDownloadingReport ? (
                <Loader2 size={16} className="animate-spin mr-1" />
              ) : (
                <FileText size={16} className="mr-1" />
              )}
              <span className="text-[12px] font-bold">
                {isDownloadingReport ? 'LOADING' : 'READ REPORT'}
              </span>
            </button>
          )}
        </div>

        {/* Tab Selector */}
        <div className="mx-4 my-3 p-1 bg-[#F1F5F9] rounded-[12px] border border-[#111111]/30 flex shrink-0">
          <button
            onClick={() => setSelectedTabIndex(0)}
            className={`flex-1 py-2 rounded-[8px] flex items-center justify-center transition-all ${
              selectedTabIndex === 0 ? 'bg-white shadow-[0_2px_4px_rgba(0,0,0,0.05)]' : 'bg-transparent'
            }`}
          >
            <MessageSquare size={13} color={selectedTabIndex === 0 ? '#FF187F' : '#4B5563'} />
            <span className={`ml-1.5 text-[9.5px] font-extrabold tracking-[0.5px] ${
              selectedTabIndex === 0 ? 'text-black' : 'text-gray-600'
            }`}>
              COLLABORATION ROOM
            </span>
          </button>
          <button
            onClick={() => setSelectedTabIndex(1)}
            className={`flex-1 py-2 rounded-[8px] flex items-center justify-center transition-all ${
              selectedTabIndex === 1 ? 'bg-white shadow-[0_2px_4px_rgba(0,0,0,0.05)]' : 'bg-transparent'
            }`}
          >
            <Map size={13} color={selectedTabIndex === 1 ? '#FF187F' : '#4B5563'} />
            <span className={`ml-1.5 text-[9.5px] font-extrabold tracking-[0.5px] ${
              selectedTabIndex === 1 ? 'text-black' : 'text-gray-600'
            }`}>
              CONSENSUS REPORT
            </span>
            {zones.length > 0 && !isComplete && (
              <div className="w-1.5 h-1.5 bg-[#FF187F] rounded-full ml-1.5" />
            )}
          </button>
        </div>

        {/* Content Area */}
        <div className="flex-1 overflow-hidden flex flex-col">
          {selectedTabIndex === 0 ? (
            <div className="flex flex-col h-full bg-[#F5F5F5]">
              {/* View Toggle */}
              <div className="mx-3 my-1 p-[3px] bg-[#F1F5F9] rounded-[10px] flex shrink-0">
                <button
                  onClick={() => setShowGraph(true)}
                  className={`flex-1 py-2 rounded-[8px] flex items-center justify-center transition-all ${
                    showGraph ? 'bg-white shadow-[0_2px_4px_rgba(0,0,0,0.05)]' : 'bg-transparent'
                  }`}
                >
                  <Map size={13} color={showGraph ? '#FF187F' : '#4B5563'} />
                  <span className={`ml-1.5 text-[9px] font-extrabold tracking-[0.3px] ${
                    showGraph ? 'text-black' : 'text-gray-600'
                  }`}>
                    ORCHESTRATION GRAPH
                  </span>
                </button>
                <button
                  onClick={() => setShowGraph(false)}
                  className={`flex-1 py-2 rounded-[8px] flex items-center justify-center transition-all ${
                    !showGraph ? 'bg-white shadow-[0_2px_4px_rgba(0,0,0,0.05)]' : 'bg-transparent'
                  }`}
                >
                  <MessageSquare size={13} color={!showGraph ? '#FF187F' : '#4B5563'} />
                  <span className={`ml-1.5 text-[9px] font-extrabold tracking-[0.3px] ${
                    !showGraph ? 'text-black' : 'text-gray-600'
                  }`}>
                    ADVISORY CHATBOX
                  </span>
                </button>
              </div>

              {showGraph ? (
                <div className="flex-1 overflow-y-auto no-scrollbar">
                  <BandOrchestrationGraph 
                    messages={messages}
                    isComplete={isComplete}
                    currentAgent={currentAgent}
                    zones={zones}
                  />
                  {/* Latest Update Card */}
                  <div className="mx-3 my-2 p-4 bg-white rounded-[16px] border border-[#111111]/15 shadow-[0_4px_10px_rgba(0,0,0,0.02)] flex items-start gap-3">
                    <div className="mt-1"><Info size={16} color="#FF187F" /></div>
                    <div className="flex flex-col flex-1">
                      <span className="text-[#FF187F] text-[9px] font-bold">LATEST UPDATE</span>
                      <span className="text-[11px] font-medium leading-[1.35] mt-1 text-black">
                        {messages.length > 0 ? `@${currentAgent}: ${statusMessage}` : "Waiting for room stream..."}
                      </span>
                    </div>
                  </div>
                </div>
              ) : (
                <CollaborationChatbox 
                  roomId={roomId}
                  messages={messages}
                  onSendMessage={handleSendMessage}
                  onOpenPdf={downloadReport}
                />
              )}
            </div>
          ) : (
            <ScoutingResultsDashboard 
              zones={zones}
              events={events}
              mapCenter={mapCenter}
              isScouting={isScouting}
              messages={messages}
              isDownloadingReport={isDownloadingReport}
              onDownloadReport={downloadReport}
              mapboxAccessToken={mapboxToken}
            />
          )}
        </div>
      </div>
    </ResponsiveWebWrapper>
  );
}
