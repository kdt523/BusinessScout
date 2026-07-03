import React from 'react';
import { Lightbulb, TrendingUp, Award, Star, Search, AlertTriangle, Filter, Sailboat } from 'lucide-react';

export default function ResearchRecommendationsCard({ oppScore, competitorCount }) {
  const recommendations = [];
  
  let accentColor = '#EF4444'; // Red
  let statusLabel = 'Caution Warranted';
  
  if (oppScore >= 7.0) {
    accentColor = '#10B981'; // Emerald Green
    statusLabel = 'Favorable Conditions';
    recommendations.push({
      title: 'High Feasibility Execution',
      desc: 'Strong market opportunity with highly favorable foot traffic and demographics. Excellent conditions for entry.',
      Icon: TrendingUp
    });
    recommendations.push({
      title: 'Premium Brand Positioning',
      desc: 'Target affluent segments and command premium pricing to maximize margins while competition is low.',
      Icon: Award
    });
  } else if (oppScore >= 5.0) {
    accentColor = '#F59E0B'; // Amber
    statusLabel = 'Differentiated Approach';
    recommendations.push({
      title: 'Differentiation Focus',
      desc: 'Moderate market density - build unique value propositions to stand out from average competitors.',
      Icon: Star
    });
    recommendations.push({
      title: 'Competitor Auditing',
      desc: 'Run targeted local audits on competitor pricing and operating hours before launching final storefront setup.',
      Icon: Search
    });
  } else {
    recommendations.push({
      title: 'Alternative Site Check',
      desc: 'Challenging market conditions detected. Consider researching alternative locations or peripheral corridors.',
      Icon: AlertTriangle
    });
    recommendations.push({
      title: 'Niche Customization',
      desc: 'If proceeding, focus on a highly specific niche market that standard mass-market competitors ignore.',
      Icon: Filter
    });
  }
  
  if (competitorCount === 0) {
    recommendations.push({
      title: 'Blue Ocean Advantage',
      desc: 'Zero active competitors found in this immediate zone. Execute rapidly to lock in the first-mover advantage.',
      Icon: Sailboat
    });
  }

  return (
    <div className="p-5 bg-white rounded-[24px] border border-[#111111]/25 shadow-[0_8px_24px_rgba(0,0,0,0.03)] flex flex-col items-start">
      <div className="flex items-center w-full">
        <div className="p-2 bg-[#111111]/10 rounded-full shrink-0">
          <Lightbulb size={18} color="#111111" />
        </div>
        <span className="ml-2.5 text-[#333333] text-[12.5px] font-black tracking-[1px] uppercase flex-1">
          STRATEGIC RECOMMENDATIONS
        </span>
        <div className="px-2 py-1 rounded-[20px] shrink-0" style={{ backgroundColor: `${accentColor}1A` }}>
          <span className="text-[8px] font-black tracking-[0.5px] uppercase" style={{ color: accentColor }}>
            {statusLabel}
          </span>
        </div>
      </div>
      
      <div className="h-5" />
      
      <div className="flex flex-col w-full gap-3">
        {recommendations.map((rec, idx) => {
          const { Icon, title, desc } = rec;
          return (
            <div key={idx} className="bg-[#FAFAFA] rounded-[16px] border border-gray-100 overflow-hidden">
              <div 
                className="p-4 flex items-start"
                style={{ borderLeft: `4.5px solid ${accentColor}` }}
              >
                <div className="p-2 rounded-full shrink-0" style={{ backgroundColor: `${accentColor}15` }}>
                  <Icon size={16} color={accentColor} />
                </div>
                <div className="ml-3.5 flex flex-col">
                  <span className="text-gray-900 text-[13px] font-bold">
                    {idx + 1}. {title}
                  </span>
                  <span className="text-gray-600 text-[11px] leading-[1.45] mt-1">
                    {desc}
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
