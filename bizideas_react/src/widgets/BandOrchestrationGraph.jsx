import React from 'react';
import { Share2, RefreshCw, CheckCircle2, ShieldCheck, FileText } from 'lucide-react';
import AgentGraphNode from './AgentGraphNode';
import { SplitBezierConnector, MergeBezierConnector, StraightBezierConnector } from './BezierConnectors';
import { Settings, Map, BarChart2, Bot } from 'lucide-react';

export default function BandOrchestrationGraph({ messages, isComplete, currentAgent, zones }) {
  const hasOrchestrationStage = (stage) => {
    return messages.some(msg => msg.type === 'orchestration' && msg.data?.stage === stage);
  };

  const roomOpen = hasOrchestrationStage('room_open') || messages.length > 0;
  const contextReady = hasOrchestrationStage('shared_context_ready') || messages.some(msg => msg.sender === 'Orchestrator');
  const parallelStarted = hasOrchestrationStage('parallel_handoff') || messages.some(msg => msg.content?.includes("Parallel research started"));
  const locationReady = hasOrchestrationStage('location_package_ready') || messages.some(msg => msg.sender === 'Location Scout' && msg.type === 'data');
  const competitorReady = hasOrchestrationStage('competitor_package_ready') || messages.some(msg => msg.sender === 'Competitor Analyst' && msg.type === 'data');
  const mergeReady = hasOrchestrationStage('merge_handoff') || messages.some(msg => msg.content?.includes("Parallel research complete"));
  const plannerReady = hasOrchestrationStage('planner_synthesis_ready') || messages.some(msg => msg.sender === 'Business Planner' && msg.type === 'data');
  const consensusReady = hasOrchestrationStage('consensus_closed') || isComplete;
  
  const eventCount = messages.filter(msg => msg.type === 'orchestration').length;

  return (
    <div className="mx-3 mt-1.5 mb-1 p-4 bg-white rounded-[24px] border border-[#E2E8F0] shadow-[0_4px_10px_rgba(0,0,0,0.02),0_15px_30px_rgba(17,17,17,0.05)]">
      <div className="flex items-center gap-2.5 mb-4">
        <div className="w-8 h-8 rounded-full border border-[#FF187F]/20 bg-[#FF187F]/10 flex items-center justify-center shrink-0">
          <Share2 size={16} color="#FF187F" />
        </div>
        <div className="flex-1 min-w-0">
          <span className="text-[12px] font-bold tracking-[0.5px] text-black block">
            ORCHESTRATION NETWORK
          </span>
          <span className="text-[8.5px] font-semibold text-[#64748B] block truncate mt-[2px]">
            {eventCount} network transmission{eventCount === 1 ? '' : 's'} recorded
          </span>
        </div>
        <div 
          className={`px-2 py-1 rounded-full border flex items-center gap-1 shrink-0 ${
            consensusReady ? 'bg-[#DCFCE7] border-[#86EFAC]' : 'bg-[#FFF1F2] border-[#FECDD3]'
          }`}
        >
          {consensusReady ? (
            <>
              <CheckCircle2 size={10} color="#10B981" />
              <span className="text-[7.2px] font-extrabold text-[#15803D]">COMPLETE</span>
            </>
          ) : (
            <>
              <RefreshCw size={10} color="#E11D48" className="animate-spin" />
              <span className="text-[7.2px] font-extrabold text-[#E11D48]">LIVE PIPELINE</span>
            </>
          )}
        </div>
      </div>

      <div className="flex flex-col">
        <AgentGraphNode
          agent="Orchestrator"
          title="1. Recruit & Context"
          subtitle={contextReady ? "Shared context package published." : roomOpen ? "Acquiring coordinator role..." : "Waiting for room stream..."}
          active={roomOpen && !contextReady}
          done={contextReady}
          color="#FF187F"
          icon={Settings}
          roleTag="Coordinator"
        />

        <SplitBezierConnector
          activeLeft={parallelStarted && !locationReady}
          activeRight={parallelStarted && !competitorReady}
          doneLeft={locationReady}
          doneRight={competitorReady}
          colorLeft="#111111"
          colorRight="#111111"
          colorParent="#FF187F"
          label="CONTEXT BROADCAST"
        />

        <div className="flex gap-3">
          <div className="flex-1">
            <AgentGraphNode
              agent="Location Scout"
              title="2A. Geographic Scout"
              subtitle={locationReady ? "Zones resolved." : parallelStarted ? "Scouting commercial zones..." : "Awaiting dispatch..."}
              active={parallelStarted && !locationReady}
              done={locationReady}
              color="#111111"
              icon={Map}
              roleTag="GIS + Bright Data"
            />
          </div>
          <div className="flex-1">
            <AgentGraphNode
              agent="Competitor Analyst"
              title="2B. Market Saturation"
              subtitle={competitorReady ? "Opportunity indexed." : parallelStarted ? "Evaluating saturation..." : "Awaiting dispatch..."}
              active={parallelStarted && !competitorReady}
              done={competitorReady}
              color="#111111"
              icon={BarChart2}
              roleTag="Market Saturation"
            />
          </div>
        </div>

        <MergeBezierConnector
          activeLeft={locationReady}
          activeRight={competitorReady}
          doneLeft={locationReady}
          doneRight={competitorReady}
          parentActive={mergeReady && !plannerReady}
          colorLeft="#111111"
          colorRight="#111111"
          colorParent="#FF187F"
          label={mergeReady ? "PACKAGES MERGED" : "PARALLEL INGEST"}
        />

        <AgentGraphNode
          agent="Business Planner"
          title="3. Decision Synthesis"
          subtitle={plannerReady ? "Feasibility PDF compiled." : mergeReady ? "Synthesizing plans..." : "Waiting for research stream..."}
          active={mergeReady && !plannerReady}
          done={plannerReady}
          color="#FF187F"
          icon={FileText}
          roleTag="Strategy Architect"
        />

        <StraightBezierConnector
          active={plannerReady && !consensusReady}
          done={consensusReady}
          color="#10B981"
          label="PUBLISH DELIVERABLE"
        />

        <div 
          className={`w-full px-[14px] py-[12px] rounded-[16px] border ${
            consensusReady ? 'bg-[#ECFDF5] border-[#10B98199] shadow-[0_4px_10px_rgba(16,185,129,0.04)]' : 'bg-white border-[#E2E8F0] shadow-[0_4px_10px_rgba(0,0,0,0.01)]'
          } flex items-center gap-3 transition-colors duration-300`}
        >
          <div 
            className={`w-8 h-8 rounded-full border flex items-center justify-center shrink-0 ${
              consensusReady ? 'bg-[#D1FAE5] border-[#6EE7B7]' : 'bg-[#F1F5F9] border-[#E2E8F0]'
            }`}
          >
            {consensusReady ? (
              <ShieldCheck size={16} color="#10B981" />
            ) : (
              <FileText size={16} color="#64748B" />
            )}
          </div>
          
          <div className="flex-1 flex flex-col">
            <span 
              className={`text-[10.5px] font-bold ${
                consensusReady ? 'text-[#065F46]' : 'text-[#334155]'
              }`}
            >
              {consensusReady ? "Consensus Finalized" : "Awaiting Consensus"}
            </span>
            <span 
              className={`text-[8.5px] leading-[1.25] mt-0.5 ${
                consensusReady ? 'text-[#047857] font-semibold' : 'text-[#64748B] font-medium'
              }`}
            >
              {consensusReady 
                ? "The decision coordinates are resolved and the Business Plan PDF is published."
                : "The final PDF report will generate automatically when all work packages compile."
              }
            </span>
          </div>
        </div>

      </div>
    </div>
  );
}
