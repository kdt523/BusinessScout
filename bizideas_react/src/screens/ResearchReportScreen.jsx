import React, { useState, useEffect, useRef } from 'react';
import { useParams, useLocation, useNavigate } from 'react-router-dom';
import { 
  ArrowLeft, 
  Download, 
  BarChart2, 
  ClipboardList, 
  FileText, 
  MapPin, 
  TrendingUp, 
  MessageSquare,
  Loader2,
  PieChart,
  ClipboardCheck,
  Map as MapIcon
} from 'lucide-react';

import ResponsiveWebWrapper from '../components/ResponsiveWebWrapper';
import ApiService from '../services/apiService';
import MarkdownText from '../components/MarkdownText';

import ResearchMetricsDashboard from '../widgets/ResearchMetricsDashboard';
import ResearchRecommendationsCard from '../widgets/ResearchRecommendationsCard';
import ResearchDetailedPlanTab from '../widgets/ResearchDetailedPlanTab';
import ResearchLandAcquisitionCard from '../widgets/ResearchLandAcquisitionCard';
import ResearchCompetitionCard from '../widgets/ResearchCompetitionCard';
import ResearchForecastCard from '../widgets/ResearchForecastCard';
import MapboxMapWidget from '../widgets/MapboxMapWidget';
import CollaborationChatbox from '../widgets/CollaborationChatbox';

export default function ResearchReportScreen() {
  const { roomId } = useParams();
  const location = useLocation();
  const navigate = useNavigate();

  const businessType = location.state?.businessType || 'Business';
  const city = location.state?.city || 'City';
  const initialReportData = location.state?.reportData || {};

  const [mapboxToken, setMapboxToken] = useState('');
  const [isDownloadingPdf, setIsDownloadingPdf] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [data, setData] = useState(initialReportData);
  const [messages, setMessages] = useState([]);
  
  const [selectedTab, setSelectedTab] = useState(0);
  const hasFetched = useRef(false);

  useEffect(() => {
    fetchMapboxToken();
    const cleanup = connectToStream();
    if (Object.keys(initialReportData).length === 0 || !initialReportData.plan_details) {
      if (!hasFetched.current) {
        fetchReportData();
        hasFetched.current = true;
      }
    }
    return cleanup;
  }, [roomId]);

  const fetchMapboxToken = async () => {
    const token = await ApiService.getMapboxAccessToken();
    setMapboxToken(token);
  };

  const fetchReportData = async () => {
    setIsLoading(true);
    try {
      const msgs = await ApiService.getRoomMessages(roomId);
      let foundData = null;

      for (const msg of msgs) {
        if (msg.sender === "Business Planner" && msg.type === "data") {
          foundData = msg.data;
          break;
        }
      }

      if (!foundData) {
        for (const msg of msgs) {
          if (msg.sender === "Competitor Analyst" && msg.type === "data") {
            const enriched = msg.data.enriched_zones;
            if (enriched && enriched.length > 0) {
              foundData = enriched[0];
            }
            break;
          }
        }
      }

      if (!foundData) {
        for (const msg of msgs) {
          if (msg.sender === "Location Scout" && msg.type === "data") {
            const zones = msg.data.zones;
            if (zones && zones.length > 0) {
              foundData = zones[0];
            }
            break;
          }
        }
      }

      if (foundData) {
        setData(foundData);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  };

  const connectToStream = () => {
    return ApiService.streamRoomMessages(
      roomId,
      (msg) => {
        setMessages(prev => [...prev, msg]);
        if (Object.keys(data).length === 0) {
          if (msg.sender === "Business Planner" && msg.type === "data") {
            setData(msg.data);
          }
        }
      },
      (err) => console.error("Stream error", err),
      () => {}
    );
  };

  const handleSendMessage = async (content) => {
    return await ApiService.sendRoomMessage(roomId, 'User', 'user', content);
  };

  const downloadPdf = () => {
    const pdfUrl = ApiService.getPdfDownloadUrl(roomId);
    window.open(pdfUrl, '_blank');
  };

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-[100dvh] bg-[#FDFDFD]">
        <Loader2 size={40} className="text-[#FF187F] animate-spin" />
        <span className="mt-5 text-gray-700 text-[14px] font-semibold">
          Reconstructing research report...
        </span>
      </div>
    );
  }

  const hasFullData = data.best_zone !== undefined;
  const zoneData = hasFullData ? (data.best_zone || {}) : data;

  const oppScore = Number(zoneData.opp_score || 0);
  const trafficScore = Number(zoneData.traffic_score || 0);
  const saturationScore = Number(zoneData.saturation_score || 0);
  const competitorCount = zoneData.competitor_count || 0;
  const competitors = Array.isArray(zoneData.competitors) ? zoneData.competitors : [];
  const zoneName = zoneData.name || 'Primary Corridor';

  const lat = Number(zoneData.lat || 0);
  const lng = Number(zoneData.lng || 0);

  const planDetails = hasFullData ? (data.plan_details || {}) : {};
  const seasonalForecast = hasFullData ? (data.seasonal_forecast || {}) : {};
  const landResearch = hasFullData ? (data.land_research || []) : [];
  const marketProfile = hasFullData ? (data.market_profile || {}) : {};

  const demographics = hasFullData ? (data.demographics || {}) : {};
  const anchorResearch = hasFullData ? (data.anchor_research || []) : [];

  let bestZoneAnchor = null;
  if (anchorResearch.length > 0) {
    for (const item of anchorResearch) {
      if (item.zone_name === zoneName) {
        bestZoneAnchor = item;
        break;
      }
    }
  }

  const tabs = [
    { name: 'Overview', Icon: BarChart2 },
    { name: 'Registration Guide', Icon: ClipboardList },
    { name: 'Strategic Plan', Icon: FileText },
    { name: 'Geographic & Site', Icon: MapPin },
    { name: 'Market & Projections', Icon: TrendingUp },
    { name: 'Advisory Chat', Icon: MessageSquare },
  ];

  return (
    <ResponsiveWebWrapper>
      <div className="flex flex-col h-[100dvh] bg-[#FDFDFD]">
        {/* App Bar */}
        <div className="bg-white px-4 py-3 flex items-center justify-between shrink-0">
          <div className="flex items-center">
            <button onClick={() => navigate(-1)} className="mr-3 p-1">
              <ArrowLeft size={18} color="black" />
            </button>
            <div className="flex flex-col">
              <span className="text-black text-[16px] font-bold">
                {businessType}
              </span>
              <span className="text-gray-500 text-[11px] font-semibold">
                {city}
              </span>
            </div>
          </div>
          <button 
            onClick={downloadPdf}
            disabled={isDownloadingPdf}
            className="flex items-center text-[#FF187F] px-4 py-2"
          >
            {isDownloadingPdf ? (
              <Loader2 size={16} className="animate-spin mr-1.5" />
            ) : (
              <Download size={16} className="mr-1.5" />
            )}
            <span className="text-[12px] font-bold">
              {isDownloadingPdf ? 'Exporting...' : 'Export PDF'}
            </span>
          </button>
        </div>

        {/* Tab Bar */}
        <div className="flex items-center overflow-x-auto no-scrollbar border-b border-[#111111]/20 bg-white shrink-0 px-2">
          {tabs.map((tab, idx) => (
            <button
              key={idx}
              onClick={() => setSelectedTab(idx)}
              className={`flex items-center px-4 py-3 shrink-0 border-b-[2.5px] transition-colors ${
                selectedTab === idx ? 'border-[#FF187F]' : 'border-transparent'
              }`}
            >
              <tab.Icon size={18} color={selectedTab === idx ? '#FF187F' : '#4B5563'} />
              <span className={`ml-2 text-[12px] ${selectedTab === idx ? 'text-[#FF187F] font-bold' : 'text-gray-600 font-semibold'}`}>
                {tab.name}
              </span>
            </button>
          ))}
        </div>

        {/* Content Area */}
        <div className="flex-1 overflow-y-auto no-scrollbar p-4">
          {selectedTab === 0 && (
            <div className="flex flex-col gap-4">
              <ExecutiveSummaryCard oppScore={oppScore} />
              
              <MapboxMapWidget 
                lat={lat}
                lng={lng}
                accessToken={mapboxToken}
                locationName={zoneName}
                zones={hasFullData ? data.zones || [] : null}
              />
              
              <ResearchMetricsDashboard 
                oppScore={oppScore}
                trafficScore={trafficScore}
                saturationScore={saturationScore}
                competitorCount={competitorCount}
                demographics={demographics}
                bestZoneAnchor={bestZoneAnchor}
              />

              <ResearchRecommendationsCard 
                oppScore={oppScore}
                competitorCount={competitorCount}
              />
            </div>
          )}

          {selectedTab === 1 && (
            <div className="flex flex-col">
              {planDetails.registration_guide ? (
                <RegistrationGuideCard content={planDetails.registration_guide} />
              ) : (
                <EmptyDataCard message="No business registration guide compiled yet. Wait for Business Planner agent to complete." />
              )}
            </div>
          )}

          {selectedTab === 2 && (
            <div className="flex flex-col">
              {Object.keys(planDetails).length > 0 ? (
                <ResearchDetailedPlanTab planDetails={planDetails} />
              ) : (
                <EmptyDataCard message="No detailed strategy plan compiled yet. Wait for Business Planner agent to complete." />
              )}
            </div>
          )}

          {selectedTab === 3 && (
            <div className="flex flex-col gap-4">
              <SectionCard 
                title="Geographic Analysis"
                Icon={MapIcon}
                color="#111111"
              >
                <InfoRow label="Recommended Corridor" value={zoneName} valueColor="#FF187F" />
                <InfoRow 
                  label="Traffic Density Rating" 
                  value={`${trafficScore.toFixed(1)}/10`} 
                  valueColor={trafficScore >= 7.0 ? '#10B981' : '#F59E0B'} 
                />
                <InfoRow 
                  label="Market Density Saturation" 
                  value={`${saturationScore.toFixed(1)}/10`} 
                  valueColor={saturationScore < 5.0 ? '#10B981' : '#F59E0B'} 
                />
              </SectionCard>

              {landResearch.length > 0 && (
                <ResearchLandAcquisitionCard 
                  landResearch={landResearch}
                  marketProfile={marketProfile}
                />
              )}
            </div>
          )}

          {selectedTab === 4 && (
            <div className="flex flex-col gap-4">
              <ResearchCompetitionCard 
                competitorCount={competitorCount}
                competitors={competitors}
              />
              {Object.keys(seasonalForecast).length > 0 && (
                <ResearchForecastCard 
                  seasonalForecast={seasonalForecast}
                />
              )}
            </div>
          )}

          {selectedTab === 5 && (
            <div className="h-full min-h-[400px] bg-white rounded-[24px] border border-[#111111]/10 shadow-[0_8px_24px_rgba(0,0,0,0.02)] overflow-hidden">
              <CollaborationChatbox 
                roomId={roomId}
                messages={messages}
                onSendMessage={handleSendMessage}
                onOpenPdf={downloadPdf}
              />
            </div>
          )}

        </div>
      </div>
    </ResponsiveWebWrapper>
  );
}

function ExecutiveSummaryCard({ oppScore }) {
  let assessment = 'Challenging Market';
  let assessmentColor = '#FF187F';

  if (oppScore >= 7.0) {
    assessment = 'Strong Opportunity';
    assessmentColor = '#10B981';
  } else if (oppScore >= 5.0) {
    assessment = 'Moderate Opportunity';
    assessmentColor = '#111111';
  }

  return (
    <div 
      className="p-5 rounded-[24px] border-[1.5px] flex flex-col items-start"
      style={{ 
        background: `linear-gradient(to bottom right, ${assessmentColor}10, white)`,
        borderColor: `${assessmentColor}40`,
        boxShadow: `0 8px 24px ${assessmentColor}0A`
      }}
    >
      <div className="flex items-center w-full">
        <div className="p-3 rounded-full shrink-0" style={{ backgroundColor: `${assessmentColor}15` }}>
          <PieChart size={24} color={assessmentColor} />
        </div>
        <div className="ml-4 flex flex-col flex-1">
          <span className="text-gray-500 text-[10px] font-black tracking-[0.8px] uppercase">
            MARKET FEASIBILITY SCORE
          </span>
          <span className="text-gray-800 text-[20px] font-bold mt-[2px]">
            {assessment}
          </span>
        </div>
        <div className="flex items-baseline shrink-0">
          <span className="text-[44px] font-black leading-none" style={{ color: assessmentColor }}>
            {oppScore.toFixed(1)}
          </span>
          <span className="text-gray-400 text-[14px] font-bold ml-1">
            /10
          </span>
        </div>
      </div>
      <div className="h-4" />
      <div className="w-full h-[10px] bg-gray-200 rounded-[6px] overflow-hidden">
        <div className="h-full" style={{ width: `${(oppScore / 10) * 100}%`, backgroundColor: assessmentColor }} />
      </div>
    </div>
  );
}

function RegistrationGuideCard({ content }) {
  return (
    <div className="p-5 bg-white rounded-[24px] border border-[#111111]/15 shadow-[0_8px_24px_rgba(0,0,0,0.02)] flex flex-col items-start">
      <div className="flex items-center">
        <div className="p-2.5 bg-[#FF187F]/10 rounded-full">
          <ClipboardCheck size={22} color="#FF187F" />
        </div>
        <div className="ml-3.5 flex flex-col">
          <span className="text-gray-500 text-[10px] font-black tracking-[0.8px] uppercase">
            COMPLIANCE & REGISTRATION
          </span>
          <span className="text-gray-800 text-[18px] font-bold mt-[2px]">
            Step-by-Step Business Guide
          </span>
        </div>
      </div>
      <div className="h-5" />
      <div className="text-black/85 text-[14px] leading-[1.5] w-full">
        <MarkdownText data={content} />
      </div>
    </div>
  );
}

function SectionCard({ title, Icon, color, children }) {
  return (
    <div className="p-5 bg-white rounded-[24px] border border-[#111111]/25 shadow-[0_8px_24px_rgba(0,0,0,0.03)] flex flex-col items-start">
      <div className="flex items-center">
        <Icon size={20} color={color} />
        <span className="ml-2 text-gray-850 text-[12.5px] font-black tracking-[0.8px] uppercase">
          {title}
        </span>
      </div>
      <div className="h-4" />
      <div className="w-full">
        {children}
      </div>
    </div>
  );
}

function InfoRow({ label, value, valueColor }) {
  return (
    <div className="flex justify-between items-center w-full pb-3 mb-3 border-b border-gray-100 last:border-0 last:mb-0 last:pb-0">
      <span className="text-gray-700 text-[13px] font-medium flex-1">
        {label}
      </span>
      <span className="text-[14px] font-bold flex-1 text-right truncate" style={{ color: valueColor }}>
        {value}
      </span>
    </div>
  );
}

function EmptyDataCard({ message }) {
  return (
    <div className="p-6 bg-white rounded-[20px] border border-gray-200 flex flex-col items-center justify-center min-h-[200px]">
      <FileText size={36} color="#D1D5DB" />
      <span className="mt-3 text-gray-500 text-[12.5px] font-medium text-center leading-[1.4] max-w-[300px]">
        {message}
      </span>
    </div>
  );
}
