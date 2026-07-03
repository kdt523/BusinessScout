import React from 'react';
import { BarChart3, Snowflake, Sun, Mountain, Gift } from 'lucide-react';

export default function ResearchForecastCard({ seasonalForecast }) {
  if (!seasonalForecast || Object.keys(seasonalForecast).length === 0) return null;

  return (
    <div className="p-[22px] bg-white rounded-[24px] border border-[#111111]/25 shadow-[0_8px_24px_rgba(0,0,0,0.03)] flex flex-col items-start">
      <div className="flex items-center">
        <div className="p-2 bg-[#FF187F]/10 rounded-full">
          <BarChart3 size={18} color="#FF187F" />
        </div>
        <span className="ml-2.5 text-[#333333] text-[12.5px] font-black tracking-[1px] uppercase">
          QUARTERLY DEMAND PROJECTIONS
        </span>
      </div>
      
      <div className="h-5" />
      
      <div className="flex flex-col w-full gap-4">
        {Object.entries(seasonalForecast).map(([quarter, description], idx) => {
          const descStr = String(description);
          const percentMatch = descStr.match(/(\d+)%/);
          const percent = percentMatch ? parseInt(percentMatch[1], 10) : 100;
          const progress = Math.min(percent / 150, 1);

          let quarterColor = '#EF4444'; // Red
          let QuarterIcon = Gift;
          if (quarter.includes('Q1')) {
            quarterColor = '#3B82F6'; // Blue
            QuarterIcon = Snowflake;
          } else if (quarter.includes('Q2')) {
            quarterColor = '#F59E0B'; // Amber
            QuarterIcon = Sun;
          } else if (quarter.includes('Q3')) {
            quarterColor = '#10B981'; // Emerald
            QuarterIcon = Mountain;
          }

          return (
            <div key={idx} className="p-3.5 bg-[#FAFAFA] rounded-[16px] border border-gray-100 flex flex-col w-full">
              <div className="flex justify-between items-center w-full">
                <div className="flex items-center">
                  <QuarterIcon size={14} color={quarterColor} />
                  <span className="ml-1.5 text-gray-800 text-[13px] font-bold">
                    {quarter.split(' - ')[0]}
                  </span>
                </div>
                <div className="px-2 py-1 rounded-[12px]" style={{ backgroundColor: `${quarterColor}1F` }}>
                  <span className="text-[10px] font-black" style={{ color: quarterColor }}>
                    {percent}% Cap
                  </span>
                </div>
              </div>
              
              <div className="h-2.5" />
              
              <div className="w-full h-[6px] bg-gray-200 rounded">
                <div className="h-full rounded" style={{ width: `${progress * 100}%`, backgroundColor: quarterColor }} />
              </div>
              
              <div className="h-2.5" />
              
              <span className="text-gray-600 text-[10.5px] font-semibold leading-[1.4]">
                {descStr}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
