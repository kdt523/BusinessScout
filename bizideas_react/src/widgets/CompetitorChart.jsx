import React from 'react';

export default function CompetitorChart({ zones }) {
  if (!zones || zones.length === 0) return null;

  return (
    <div className="flex flex-col">
      <span className="text-black text-[13px] font-bold tracking-[0.3px] mb-2.5">
        Location Feasibility Score Comparison
      </span>
      <div className="flex flex-col gap-2.5">
        {zones.map((zone, index) => {
          const traffic = typeof zone.traffic_score === 'number' ? zone.traffic_score : 0;
          const saturation = typeof zone.saturation_score === 'number' ? zone.saturation_score : 0;
          const oppScore = typeof zone.opp_score === 'number' ? zone.opp_score : 0;
          const competitors = zone.competitor_count || 0;

          const isFirst = index === 0;
          const scoreColor = isFirst ? '#FF187F' : '#111111';

          let satColor = '#10B981'; // Green
          if (saturation >= 7.0) satColor = '#FF187F';
          else if (saturation >= 4.0) satColor = '#111111';

          return (
            <div 
              key={index} 
              className={`p-3 bg-white rounded-[16px] border ${
                isFirst ? 'border-[#FF187F]/40 border-[1.5px]' : 'border-[#111111]/15 border'
              } shadow-[0_4px_10px_rgba(0,0,0,0.02)] flex items-center`}
            >
              {/* Opportunity Score Circle */}
              <div 
                className={`w-[52px] h-[52px] rounded-full border-2 flex flex-col items-center justify-center shrink-0 ${
                  isFirst ? 'bg-[#FF187F]/5 border-[#FF187F]' : 'bg-[#111111]/5 border-[#111111]'
                }`}
              >
                <span className={`text-[16px] font-bold leading-none ${isFirst ? 'text-[#FF187F]' : 'text-[#111111]'}`}>
                  {oppScore.toFixed(1)}
                </span>
                <span className="text-gray-400 text-[6px] font-bold mt-[2px]">INDEX</span>
              </div>
              
              <div className="w-3 shrink-0" />
              
              {/* Details and Progress Bars */}
              <div className="flex-1 flex flex-col">
                <div className="flex justify-between items-center w-full">
                  <span className="text-black text-[12px] font-bold truncate pr-2 flex-1">
                    #{index + 1} {zone.name || `Zone ${index + 1}`}
                  </span>
                  <span className="text-[10px] font-bold shrink-0" style={{ color: satColor }}>
                    {competitors} Competitors
                  </span>
                </div>
                
                <div className="h-2" />
                
                {/* Foot Traffic Bar */}
                <div className="flex items-center w-full">
                  <span className="w-[75px] text-gray-500 text-[9px] shrink-0">Foot Traffic:</span>
                  <div className="flex-1 h-[6px] bg-[#F1F1F1] rounded">
                    <div 
                      className="h-full bg-[#111111] rounded" 
                      style={{ width: `${(traffic / 10) * 100}%` }} 
                    />
                  </div>
                  <span className="ml-1.5 text-black text-[9px] font-bold shrink-0">
                    {traffic.toFixed(1)}/10
                  </span>
                </div>
                
                <div className="h-1" />
                
                {/* Saturation Bar */}
                <div className="flex items-center w-full">
                  <span className="w-[75px] text-gray-500 text-[9px] shrink-0">Saturation:</span>
                  <div className="flex-1 h-[6px] bg-[#F1F1F1] rounded">
                    <div 
                      className="h-full rounded" 
                      style={{ width: `${(saturation / 10) * 100}%`, backgroundColor: satColor }} 
                    />
                  </div>
                  <span className="ml-1.5 text-black text-[9px] font-bold shrink-0">
                    {saturation.toFixed(1)}/10
                  </span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
