import React from 'react';
import { FileText, Star, DollarSign, Rocket, LayoutTemplate } from 'lucide-react';
import MarkdownText from '../components/MarkdownText';

export default function ResearchDetailedPlanTab({ planDetails }) {
  const hasSummary = Boolean(planDetails.executive_summary);
  const hasUvp = Boolean(planDetails.uvp);
  const hasFinancials = Boolean(planDetails.financials);
  const hasMarketing = Boolean(planDetails.marketing);
  const hasFullPlan = Boolean(planDetails.full_plan);

  return (
    <div className="flex flex-col">
      {hasSummary && (
        <PlanCard 
          title="Executive Summary"
          Icon={FileText}
          content={planDetails.executive_summary}
          accentColor="#FF187F"
        />
      )}
      {hasUvp && (
        <PlanCard 
          title="Unique Value Proposition"
          Icon={Star}
          content={planDetails.uvp}
          accentColor="#111111"
        />
      )}
      {hasFinancials && (
        <PlanCard 
          title="Year 1 Financial Targets"
          Icon={DollarSign}
          content={planDetails.financials}
          accentColor="#8B5CF6"
        />
      )}
      {hasMarketing && (
        <PlanCard 
          title="Marketing & Launch Strategy"
          Icon={Rocket}
          content={planDetails.marketing}
          accentColor="#10B981"
        />
      )}
      {hasFullPlan && (
        <FullPlanBlueprint 
          title="Complete Strategic Feasibility Plan"
          Icon={LayoutTemplate}
          content={planDetails.full_plan}
          accentColor="#FF187F"
        />
      )}
    </div>
  );
}

function PlanCard({ title, Icon, content, accentColor }) {
  return (
    <div className="mb-4 bg-white rounded-[20px] shadow-[0_6px_16px_rgba(0,0,0,0.03)] border border-[#111111]/20 overflow-hidden">
      <div 
        className="p-5"
        style={{ borderLeft: `5px solid ${accentColor}` }}
      >
        <div className="flex items-center">
          <div className="p-2 rounded-full" style={{ backgroundColor: `${accentColor}15` }}>
            <Icon size={16} color={accentColor} />
          </div>
          <span className="ml-3 text-gray-800 text-[11.5px] font-black tracking-[0.8px] uppercase">
            {title}
          </span>
        </div>
        <div className="w-full h-[1px] bg-[#EEEEEE] my-3.5" />
        <div className="text-black/85 text-[12.5px] leading-[1.5]">
          <MarkdownText data={content} />
        </div>
      </div>
    </div>
  );
}

function FullPlanBlueprint({ title, Icon, content, accentColor }) {
  return (
    <div className="mb-4 p-[22px] bg-[#F8FAFC] rounded-[24px] border-[1.5px] border-[#E2E8F0] shadow-[0_10px_20px_rgba(0,0,0,0.02)]">
      <div className="flex items-center">
        <div className="p-2.5 rounded-[12px] border" style={{ backgroundColor: `${accentColor}15`, borderColor: `${accentColor}33` }}>
          <Icon size={20} color={accentColor} />
        </div>
        <div className="ml-3.5 flex flex-col">
          <span className="text-gray-900 text-[12px] font-black tracking-[0.8px] uppercase">
            {title}
          </span>
          <span className="text-gray-500 text-[9.5px] font-medium mt-[2px]">
            Synthesized AI Agent Consensus Plan
          </span>
        </div>
      </div>
      <div className="mt-5 p-[18px] bg-white rounded-[16px] border border-[#EDF2F7]">
        <div className="text-black/85 text-[12.2px] leading-[1.55]">
          <MarkdownText data={content} />
        </div>
      </div>
    </div>
  );
}
