import React from 'react';
import { 
  LayoutDashboard, 
  Footprints, 
  Store, 
  Users, 
  Waypoints,
  Building2
} from 'lucide-react';

export default function ResearchMetricsDashboard({
  oppScore,
  trafficScore,
  saturationScore,
  competitorCount,
  demographics,
  bestZoneAnchor
}) {
  const popLabel = demographics?.population_label || 'Unavailable';
  const popSource = demographics?.source || 'Local Presets';
  const popConfidence = demographics?.confidence || 'medium';
  const studentPop = demographics?.student_population || 'Estimated 15-20%';

  const anchorScore = typeof bestZoneAnchor?.anchor_score === 'number' ? bestZoneAnchor.anchor_score : 0;
  const anchorCounts = bestZoneAnchor?.anchor_counts || {};
  const mallsCount = anchorCounts.malls || 0;
  const schoolsCount = (anchorCounts.schools || 0) + (anchorCounts.colleges_universities || 0);
  const transitCount = anchorCounts.transit_hubs || 0;

  return (
    <div className="p-5 bg-white rounded-[24px] border border-[#111111]/25 shadow-[0_8px_24px_rgba(0,0,0,0.03)] flex flex-col items-start">
      <div className="flex items-center">
        <div className="p-2 bg-[#FF187F]/10 rounded-full">
          <LayoutDashboard size={18} className="text-[#FF187F]" />
        </div>
        <span className="ml-2.5 text-[#333333] text-[12.5px] font-black tracking-[1px] uppercase">
          FEASIBILITY INSIGHTS & METRICS
        </span>
      </div>
      
      <div className="h-5" />
      
      <div className="flex flex-col w-full gap-3.5">
        <div className="flex gap-3.5 w-full">
          <MetricCard 
            title="Foot Traffic Flow"
            value={`${trafficScore.toFixed(1)}/10`}
            subtitle={trafficScore >= 8.0 ? 'High Pedestrian Flow' : trafficScore >= 6.0 ? 'Moderate Pedestrian Flow' : 'Low Pedestrian Flow'}
            Icon={Footprints}
            color="#10B981"
            progress={trafficScore / 10}
          />
          <MetricCard 
            title="Market Saturation"
            value={`${saturationScore.toFixed(1)}/10`}
            subtitle={saturationScore >= 7.0 ? 'Saturated (High Risk)' : saturationScore >= 4.0 ? 'Moderate Competition' : 'Low Saturation (Favorable)'}
            Icon={Store}
            color={saturationScore >= 7.0 ? '#EF4444' : saturationScore >= 4.0 ? '#F59E0B' : '#3B82F6'}
            progress={saturationScore / 10}
          />
        </div>
        
        <div className="flex gap-3.5 w-full">
          <DemographicCard 
            title="Total Population"
            value={popLabel}
            source={popSource}
            confidence={popConfidence}
            studentPopulation={studentPop}
            Icon={Users}
            color="#8B5CF6"
          />
          <AnchorCard 
            title="Demand Anchors"
            scoreValue={`${anchorScore.toFixed(1)}/10`}
            malls={mallsCount}
            schools={schoolsCount}
            transit={transitCount}
            Icon={Waypoints}
            color="#EC4899"
            progress={anchorScore / 10}
          />
        </div>
      </div>
      
      <div className="h-5" />
      <CompetitorMetric count={competitorCount} />
    </div>
  );
}

function MetricCard({ title, value, subtitle, Icon, color, progress }) {
  return (
    <div className="flex-1 p-4 h-[140px] bg-[#FAFAFA] rounded-[16px] border border-gray-100 flex flex-col items-start">
      <div className="flex items-center w-full">
        <Icon size={16} color={color} />
        <span className="ml-1.5 text-gray-500 text-[9.5px] font-extrabold tracking-[0.5px] uppercase truncate">
          {title}
        </span>
      </div>
      <div className="flex-1" />
      <span className="text-[26px] font-black leading-[1.1]" style={{ color }}>
        {value}
      </span>
      <span className="mt-1 text-gray-700 text-[9.5px] font-semibold truncate w-full">
        {subtitle}
      </span>
      <div className="h-2.5" />
      <div className="w-full h-[5px] bg-gray-200 rounded">
        <div className="h-full rounded" style={{ width: `${progress * 100}%`, backgroundColor: color }} />
      </div>
    </div>
  );
}

function DemographicCard({ title, value, source, confidence, studentPopulation, Icon, color }) {
  const isPreset = source.includes('Presets') || source.includes('Fallback');
  const sourceShort = isPreset ? 'Local Preset' : 'Live Census';
  const confidenceColor = confidence.toLowerCase() === 'high' ? '#10B981' : '#F59E0B';

  return (
    <div className="flex-1 p-4 h-[140px] bg-[#FAFAFA] rounded-[16px] border border-gray-100 flex flex-col items-start">
      <div className="flex items-center w-full">
        <Icon size={16} color={color} />
        <span className="ml-1.5 text-gray-500 text-[9.5px] font-extrabold tracking-[0.5px] uppercase truncate">
          {title}
        </span>
      </div>
      <div className="flex-1" />
      <span className="text-gray-900 text-[26px] font-black leading-[1.1]">
        {value}
      </span>
      <div className="mt-1 flex items-center w-full">
        <div className="px-1.5 py-0.5 rounded flex items-center justify-center" style={{ backgroundColor: `${confidenceColor}20` }}>
          <span className="text-[7.5px] font-extrabold uppercase" style={{ color: confidenceColor }}>
            {confidence}
          </span>
        </div>
        <span className="ml-1.5 text-gray-600 text-[9px] font-semibold truncate">
          {sourceShort}
        </span>
      </div>
      <div className="h-2.5" />
      <span className="text-gray-600 text-[8.5px] font-bold truncate w-full">
        Student Market: {studentPopulation}
      </span>
    </div>
  );
}

function AnchorCard({ title, scoreValue, malls, schools, transit, Icon, color, progress }) {
  return (
    <div className="flex-1 p-4 h-[140px] bg-[#FAFAFA] rounded-[16px] border border-gray-100 flex flex-col items-start">
      <div className="flex items-center w-full">
        <Icon size={16} color={color} />
        <span className="ml-1.5 text-gray-500 text-[9.5px] font-extrabold tracking-[0.5px] uppercase truncate">
          {title}
        </span>
      </div>
      <div className="flex-1" />
      <div className="flex items-baseline">
        <span className="text-gray-950 text-[26px] font-black leading-[1.1]">
          {scoreValue.split('/')[0]}
        </span>
        <span className="text-gray-400 text-[13px] font-bold">
          /10
        </span>
      </div>
      <span className="mt-1 text-gray-700 text-[9.2px] font-bold truncate w-full">
        Malls:{malls} Schools:{schools} Transit:{transit}
      </span>
      <div className="h-2.5" />
      <div className="w-full h-[5px] bg-gray-200 rounded">
        <div className="h-full rounded" style={{ width: `${progress * 100}%`, backgroundColor: color }} />
      </div>
    </div>
  );
}

function CompetitorMetric({ count }) {
  const color = "#111111";
  return (
    <div className="w-full p-4 rounded-[16px] border border-[#111111]/15 bg-[#111111]/5 flex items-center">
      <div className="p-2.5 bg-[#111111]/10 rounded-full shrink-0">
        <Building2 size={20} color={color} />
      </div>
      <div className="ml-3.5 flex flex-col flex-1">
        <span className="text-gray-500 text-[8.5px] font-extrabold tracking-[0.5px] uppercase">
          COMPETITIVE LANDSCAPE
        </span>
        <span className="mt-[3px] text-black/85 text-[13px] font-bold">
          {count === 0 ? 'Blue Ocean Market Scenario' : `${count} Active Competitors Identified`}
        </span>
      </div>
      <div className="px-3 py-1.5 bg-white rounded-[10px] border border-[#111111]/20 shrink-0">
        <span className="text-[22px] font-black leading-none" style={{ color }}>
          {count}
        </span>
      </div>
    </div>
  );
}
