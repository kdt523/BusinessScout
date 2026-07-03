import React from 'react';
import { Map, MapPin, Calendar, FileText, Download, Target, Loader2 } from 'lucide-react';
import MapboxMapWidget from './MapboxMapWidget';
import CompetitorChart from './CompetitorChart';
import MarkdownText from '../components/MarkdownText';

export default function ScoutingResultsDashboard({
  zones,
  events,
  mapCenter,
  isScouting,
  messages,
  isDownloadingReport,
  onDownloadReport,
  mapboxAccessToken
}) {
  if (!zones || zones.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full min-h-[300px]">
        <Map size={48} className="text-gray-300" />
        <div className="h-3" />
        <span className="text-gray-600 text-[13px] font-medium">No geographic data gathered yet.</span>
        <div className="h-1" />
        <span className="text-gray-400 text-[11px]">Waiting for Location Scout to map the area...</span>
      </div>
    );
  }

  const hasPlannerData = messages.some(msg => msg.sender === "Business Planner" && msg.type === "data");
  const plannerMsg = hasPlannerData 
    ? messages.find(msg => msg.sender === "Business Planner" && msg.type === "data") 
    : null;

  const planDetails = plannerMsg?.data?.plan_details || {};
  const seasonalForecast = plannerMsg?.data?.seasonal_forecast || {};

  let centerLat = 13.6218;
  let centerLng = 123.1952;
  if (zones.length > 0 && zones[0].lat != null && zones[0].lng != null) {
    centerLat = Number(zones[0].lat);
    centerLng = Number(zones[0].lng);
  } else if (mapCenter && mapCenter.lat != null && mapCenter.lng != null) {
    centerLat = Number(mapCenter.lat);
    centerLng = Number(mapCenter.lng);
  }

  return (
    <div className="p-4 flex flex-col gap-4 overflow-y-auto">
      {/* GIS Map */}
      <MapboxMapWidget 
        lat={centerLat}
        lng={centerLng}
        accessToken={mapboxAccessToken}
        locationName={zones[0]?.name || 'Best Site'}
        zones={zones}
      />

      {/* Competitor Chart */}
      {zones.length > 0 && zones[0].opp_score !== undefined && (
        <CompetitorChart zones={zones} />
      )}

      {/* Recommended Zone Card */}
      <RecommendedZoneCard zone={zones[0]} />

      {/* Local Events Card */}
      <LocalEventsCard events={events} />

      {/* Strategic Plan Card */}
      {hasPlannerData && (
        <StrategicPlanCard planDetails={planDetails} seasonalForecast={seasonalForecast} />
      )}

      {/* PDF Download Card */}
      <PdfDownloadCard 
        isDownloading={isDownloadingReport} 
        onDownload={onDownloadReport} 
      />
    </div>
  );
}

function RecommendedZoneCard({ zone }) {
  if (!zone) {
    return (
      <div className="w-full p-4 bg-white rounded-[20px] border border-gray-300 flex flex-col items-center">
        <Target size={32} className="text-gray-400" />
        <span className="text-gray-600 text-xs mt-2">No zone data available</span>
      </div>
    );
  }

  const name = zone.name || 'Zone 1';
  const parseScore = (val, def) => {
    if (val == null) return def;
    const num = Number(val);
    return isNaN(num) ? def : num;
  };

  const traffic = parseScore(zone.traffic_score, 0);
  const saturation = parseScore(zone.saturation_score, 0);
  const oppScore = parseScore(zone.opp_score, 0);
  const competitors = zone.competitor_count || 0;
  const compsList = Array.isArray(zone.competitors) ? zone.competitors : [];

  return (
    <div className="w-full p-4 bg-white rounded-[20px] border-[1.5px] border-[#FF187F]/60 shadow-[0_6px_16px_rgba(255,24,127,0.04)] flex flex-col items-start">
      <div className="flex items-center w-full justify-between">
        <div className="px-2 py-1 bg-[#FF187F] rounded-[6px]">
          <span className="text-white text-[8.5px] font-black tracking-wide">RECOMMENDED ZONE</span>
        </div>
        <span className="text-gray-500 text-[8px] font-bold">OPPORTUNITY INDEX</span>
      </div>
      
      <div className="flex items-center w-full justify-between mt-2">
        <h3 className="text-black text-[18px] font-bold flex-1 truncate">{name}</h3>
        <span className="text-[#FF187F] text-[28px] font-black">{oppScore.toFixed(1)}</span>
      </div>

      <div className="w-full h-[1px] bg-gray-100 my-3" />

      <span className="text-gray-800 text-[8.5px] font-bold tracking-[0.5px]">COMPETITOR SATURATION ANALYSIS</span>
      <p className="text-black/80 text-[11px] leading-[1.4] mt-1.5">
        {competitors === 0 
          ? "Blue ocean opportunity! There are no registered competitors in this sector."
          : `This zone contains ${competitors} active competitor outlet${competitors === 1 ? '' : 's'}. Foot traffic is rated at ${traffic.toFixed(1)}/10 and saturation is rated at ${saturation.toFixed(1)}/10.`}
      </p>

      {compsList.length > 0 && (
        <div className="flex flex-wrap gap-1.5 mt-2">
          {compsList.map((comp, idx) => (
            <div key={idx} className="px-2 py-1 bg-gray-100 border border-gray-200 rounded-[6px]">
              <span className="text-gray-700 text-[9px] font-medium">{String(comp)}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function LocalEventsCard({ events }) {
  if (!events || events.length === 0) return null;

  return (
    <div className="w-full p-4 bg-white rounded-[20px] border border-[#111111]/50 shadow-[0_6px_16px_rgba(17,17,17,0.04)] flex flex-col">
      <div className="flex items-center w-full">
        <Calendar size={14} className="text-black" />
        <span className="text-black text-[12px] font-bold tracking-[0.3px] ml-1.5 flex-1 truncate">
          LOCAL EVENTS & SEASONAL PEAKS
        </span>
        <div className="px-1.5 py-0.5 bg-[#F1F5F9] border border-[#111111]/30 rounded-[4px] ml-2">
          <span className="text-gray-600 text-[6.5px] font-black">BRIGHT DATA SCRAPED</span>
        </div>
      </div>

      <p className="text-black/50 text-[10px] leading-[1.35] mt-3 mb-3">
        The following local calendar events shape seasonal customer flow, student presence, and tourist foot traffic surges in the area:
      </p>

      <div className="flex flex-col gap-2">
        {events.map((event, idx) => (
          <div key={idx} className="p-2.5 bg-[#FDFDFD] border border-gray-100 rounded-[10px] flex items-start gap-2.5">
            <div className="p-1.5 bg-[#FF187F]/10 rounded-full shrink-0">
              <MapPin size={14} className="text-[#FF187F]" />
            </div>
            <div className="flex flex-col flex-1">
              <div className="flex items-center">
                <span className="text-black text-[11px] font-bold flex-1">{event.name || 'Local Event'}</span>
                <div className="px-1 py-[1px] bg-[#111111] rounded-[4px] ml-1">
                  <span className="text-white text-[6.5px] font-black uppercase">{event.period || 'Seasonal'}</span>
                </div>
              </div>
              <span className="text-gray-700 text-[9.5px] leading-[1.3] mt-1">{event.impact || 'Commercial spike'}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function StrategicPlanCard({ planDetails, seasonalForecast }) {
  if (!planDetails) return null;

  return (
    <div className="w-full p-4 bg-white rounded-[20px] border border-[#111111]/50 shadow-[0_6px_16px_rgba(17,17,17,0.04)] flex flex-col">
      <div className="flex items-center">
        <FileText size={16} className="text-black" />
        <span className="text-black text-[12px] font-bold ml-1.5">STRATEGIC FEASIBILITY PLAN</span>
      </div>
      <div className="h-3" />

      {planDetails.executive_summary && (
        <PlanSection title="Executive Summary" content={planDetails.executive_summary} color="#FF187F" />
      )}
      {planDetails.uvp && (
        <PlanSection title="Unique Value Proposition" content={planDetails.uvp} color="#111111" />
      )}
      {planDetails.financials && (
        <PlanSection title="Year 1 Financial Targets" content={planDetails.financials} color="#111111" />
      )}

      {seasonalForecast && Object.keys(seasonalForecast).length > 0 && (
        <div className="mt-2">
          <span className="text-gray-500 text-[8.5px] font-bold tracking-[0.5px]">QUARTERLY DEMAND PROJECTIONS</span>
          <div className="h-1.5" />
          <div className="flex flex-col gap-1.5">
            {Object.entries(seasonalForecast).map(([key, value]) => (
              <div key={key} className="flex items-start">
                <span className="text-[#FF187F] text-[10px] mr-1">⚡</span>
                <p className="text-[11px]">
                  <span className="text-black font-bold">{key}: </span>
                  <span className="text-gray-800">{value}</span>
                </p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function PlanSection({ title, content, color }) {
  return (
    <div className="flex flex-col mb-3">
      <div className="flex items-center">
        <div className="w-1 h-2.5 rounded-[2px]" style={{ backgroundColor: color }} />
        <span className="text-gray-500 text-[8.5px] font-bold tracking-[0.5px] ml-1.5 uppercase">{title}</span>
      </div>
      <div className="mt-1.5">
        <MarkdownText data={content} />
      </div>
    </div>
  );
}

function PdfDownloadCard({ isDownloading, onDownload }) {
  return (
    <div className="p-4 bg-white rounded-[20px] border border-[#FF187F]/50 shadow-[0_4px_12px_rgba(255,24,127,0.04)] flex items-center">
      <FileText size={28} className="text-[#FF187F] shrink-0" />
      <div className="flex flex-col ml-3 flex-1">
        <span className="text-black text-[13px] font-bold">Consensual Strategy Document</span>
        <span className="text-gray-500 text-[9px]">Full Report PDF compiled by Business Planner</span>
      </div>
      <button 
        onClick={onDownload}
        disabled={isDownloading}
        className="ml-2 px-3.5 py-2.5 bg-gradient-to-r from-[#FF187F] to-[#FF489F] rounded-[10px] flex items-center gap-1.5 disabled:opacity-70 hover:opacity-90 transition-opacity"
      >
        {isDownloading ? (
          <Loader2 size={14} className="text-white animate-spin" />
        ) : (
          <Download size={14} className="text-white" />
        )}
        <span className="text-white text-[9.5px] font-bold tracking-[0.5px]">
          {isDownloading ? 'SAVING' : 'SAVE'}
        </span>
      </button>
    </div>
  );
}
