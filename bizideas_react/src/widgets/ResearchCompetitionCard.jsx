import React from 'react';
import { Store, Sailboat } from 'lucide-react';

export default function ResearchCompetitionCard({ competitorCount, competitors }) {
  return (
    <div className="p-[22px] bg-white rounded-[24px] border border-[#111111]/25 shadow-[0_8px_24px_rgba(0,0,0,0.03)] flex flex-col items-start">
      <div className="flex items-center">
        <div className="p-2 bg-[#FF187F]/10 rounded-full">
          <Store size={18} color="#FF187F" />
        </div>
        <span className="ml-2.5 text-[#333333] text-[12.5px] font-black tracking-[1px] uppercase">
          COMPETITOR LANDSCAPE ANALYSIS
        </span>
      </div>
      
      <div className="h-5" />
      
      {competitorCount === 0 ? (
        <div className="p-5 w-full rounded-[18px] border-[1.5px] border-[#10B981]/25 bg-gradient-to-br from-[#E6F4EA] to-white shadow-[0_4px_10px_rgba(16,185,129,0.05)] flex items-center">
          <div className="p-2.5 bg-[#10B981]/10 rounded-full shrink-0">
            <Sailboat size={24} color="#10B981" />
          </div>
          <div className="ml-4 flex flex-col">
            <span className="text-[#15803D] text-[10px] font-black tracking-[0.5px]">
              BLUE OCEAN OPPORTUNITY
            </span>
            <span className="text-gray-700 text-[12px] font-semibold leading-[1.4] mt-[2px]">
              No registered competitors in this sector. High first-mover advantage!
            </span>
          </div>
        </div>
      ) : (
        <>
          <span className="text-gray-600 text-[12.5px] font-semibold leading-[1.4]">
            Identified {competitorCount} active commercial competitors in the immediate area:
          </span>
          <div className="h-4" />
          <div className="flex flex-wrap gap-2.5 w-full">
            {competitors.map((comp, idx) => {
              const nameStr = String(comp);
              const initial = nameStr.length > 0 ? nameStr[0].toUpperCase() : 'C';

              return (
                <div key={idx} className="px-3.5 py-2.5 bg-[#FAFAFA] rounded-[14px] border border-gray-100 flex items-center shrink-0 max-w-full">
                  <div className="w-[22px] h-[22px] rounded-full bg-[#111111]/15 border border-[#111111]/40 flex items-center justify-center shrink-0">
                    <span className="text-[#5D4037] text-[10px] font-black">
                      {initial}
                    </span>
                  </div>
                  <span className="ml-2 text-gray-800 text-[12px] font-bold truncate">
                    {nameStr}
                  </span>
                </div>
              );
            })}
          </div>
        </>
      )}
    </div>
  );
}
