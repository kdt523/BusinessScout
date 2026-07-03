import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Settings, Map, BarChart2, FileText, Bot, Send, Info, ChevronDown, ChevronUp, Download, Cpu } from 'lucide-react';
import MarkdownText from '../components/MarkdownText';

const SUGGESTED_MENTIONS = [
  "@Orchestrator",
  "@Location Scout",
  "@Competitor Analyst",
  "@Business Planner",
];

export default function CollaborationChatbox({ roomId, messages, onSendMessage, onOpenPdf }) {
  const [inputText, setInputText] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [expandedMessages, setExpandedMessages] = useState({});
  const inputRef = useRef(null);
  const scrollRef = useRef(null);

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages]);

  const insertMention = (mention) => {
    setInputText(prev => {
      // Very basic insertion at the end for simplicity
      // (in a real app you'd insert at cursor position, but this is adequate for React port)
      return prev ? `${prev} ${mention} ` : `${mention} `;
    });
    inputRef.current?.focus();
  };

  const handleSend = async () => {
    const text = inputText.trim();
    if (!text || isSending) return;

    setIsSending(true);
    const success = await onSendMessage(text);
    if (success) {
      setInputText("");
    } else {
      alert("Failed to transmit message to mesh.");
    }
    setIsSending(false);
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const toggleExpand = (index) => {
    setExpandedMessages(prev => ({ ...prev, [index]: !prev[index] }));
  };

  return (
    <div className="flex flex-col h-full bg-[#F5F5F5]">
      {/* Message Feed */}
      <div 
        ref={scrollRef}
        className="flex-1 mx-3 my-1 p-3 bg-white rounded-[20px] border border-[#111111]/15 shadow-[0_8px_24px_rgba(0,0,0,0.015)] overflow-y-auto"
      >
        {messages.length === 0 ? (
          <div className="h-full flex items-center justify-center">
            <span className="text-gray-400 text-xs">Connecting to Band room event mesh...</span>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {messages.map((msg, index) => (
              <MessageRow 
                key={msg.id || index} 
                msg={msg} 
                isExpanded={!!expandedMessages[index]}
                onToggle={() => toggleExpand(index)}
                onOpenPdf={onOpenPdf}
              />
            ))}
          </div>
        )}
      </div>

      {/* Quick Mentions Rail */}
      <div className="h-[38px] mx-3 my-1 overflow-x-auto flex items-center gap-2 no-scrollbar shrink-0">
        {SUGGESTED_MENTIONS.map(mention => (
          <button
            key={mention}
            onClick={() => insertMention(mention)}
            className="shrink-0 h-[26px] px-2 bg-[#F1F5F9] border border-[#FF187F]/15 rounded-full flex items-center justify-center hover:bg-[#E2E8F0] transition-colors"
          >
            <span className="text-[#FF187F] text-[10px] font-bold">{mention}</span>
          </button>
        ))}
      </div>

      {/* Input Field Bar */}
      <div className="mx-3 mt-1 mb-3 p-1.5 bg-white rounded-[16px] border-[1.5px] border-[#E2E8F0] shadow-[0_4px_10px_rgba(0,0,0,0.03)] flex items-center shrink-0">
        <textarea
          ref={inputRef}
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Mention agent to prompt research..."
          className="flex-1 max-h-[100px] text-[13px] text-black bg-transparent border-none outline-none resize-none px-2.5 py-2 no-scrollbar"
          rows={1}
        />
        <div className="w-1.5 shrink-0" />
        <button
          onClick={handleSend}
          disabled={isSending}
          className="w-9 h-9 shrink-0 rounded-full bg-gradient-to-br from-[#FF187F] to-[#FF489F] shadow-[0_3px_8px_rgba(255,24,127,0.3)] flex items-center justify-center disabled:opacity-70 hover:opacity-90 transition-opacity"
        >
          {isSending ? (
            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          ) : (
            <Send size={16} className="text-white ml-0.5" />
          )}
        </button>
      </div>
    </div>
  );
}

// ---------------------------------
// Subcomponents
// ---------------------------------

function MessageRow({ msg, isExpanded, onToggle, onOpenPdf }) {
  const isUser = msg.role === 'user' || msg.sender.toLowerCase() === 'user' || msg.sender.toLowerCase() === 'client';

  if (isUser) {
    return (
      <motion.div 
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="self-end ml-12 mb-1"
      >
        <div className="px-[14px] py-[10px] bg-[#1E293B] rounded-t-[16px] rounded-bl-[16px] shadow-[0_3px_6px_rgba(0,0,0,0.05)]">
          <p className="text-white text-[12px] font-medium leading-[1.35]">
            <ParsedMentions text={msg.content} />
          </p>
        </div>
      </motion.div>
    );
  }

  if (msg.role === 'system' || msg.type === 'status') {
    if (msg.type === 'orchestration') return null;

    return (
      <motion.div 
        initial={{ opacity: 0, y: 5 }}
        animate={{ opacity: 1, y: 0 }}
        className="my-1.5 px-3 py-1.5 bg-[#F1F5F9] rounded-[10px] border border-[#111111]/10 flex items-start gap-2"
      >
        <Info size={13} className="text-black mt-0.5 shrink-0" />
        <p className="text-gray-800 text-[10.5px] font-medium italic">
          {msg.content}
        </p>
      </motion.div>
    );
  }

  // Agent message
  const agentColor = getAgentColor(msg.sender);
  const AgentIcon = getAgentIcon(msg.sender);
  const roleTag = getAgentRoleTag(msg.sender);
  const cleanContent = getMessageContentForDisplay(msg);
  const preview = getMessagePreview(cleanContent);
  const hasPdf = msg.sender === 'Business Planner' && msg.data?.pdf_url;

  return (
    <motion.div 
      initial={{ opacity: 0, scale: 0.98 }}
      animate={{ opacity: 1, scale: 1 }}
      className="mb-1"
    >
      <div 
        onClick={onToggle}
        className="cursor-pointer bg-white rounded-[14px] p-3 transition-colors duration-200 border"
        style={{ borderColor: isExpanded ? `${agentColor}a6` : '#1111111e', borderWidth: isExpanded ? 1.2 : 0.8 }}
      >
        <div className="flex items-start gap-2.5">
          <div 
            className="w-8 h-8 rounded-full border-[1.4px] flex items-center justify-center shrink-0"
            style={{ backgroundColor: `${agentColor}14`, borderColor: agentColor }}
          >
            <AgentIcon size={16} color={agentColor} />
          </div>
          
          <div className="flex-1 flex flex-col justify-center">
            <span className="text-[12.5px] font-extrabold truncate" style={{ color: agentColor === '#000000' ? '#000' : agentColor }}>
              {msg.sender}
            </span>
            <span className="text-gray-500 text-[8.5px] font-bold mt-[2px] truncate">
              {roleTag}
            </span>
            {msg.data?.diagnostics && (
              <div className="mt-1">
                <DiagnosticsBadge diag={msg.data.diagnostics} />
              </div>
            )}
          </div>

          <div className="px-1.5 py-1 bg-[#F1F5F9] rounded-lg border border-gray-200 flex items-center gap-1 shrink-0">
            {isExpanded ? <ChevronUp size={12} color={agentColor} /> : <ChevronDown size={12} color={agentColor} />}
            <span className="text-[8px] font-black" style={{ color: agentColor === '#000000' ? '#000' : agentColor }}>
              {isExpanded ? 'OPEN' : 'FOLDED'}
            </span>
          </div>
        </div>

        <div className="mt-2.5">
          <AnimatePresence initial={false} mode="wait">
            {!isExpanded ? (
              <motion.div
                key="preview"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.15 }}
                className="text-gray-800 text-[10.5px] font-medium leading-[1.35] line-clamp-3"
              >
                {preview}
              </motion.div>
            ) : (
              <motion.div
                key="full"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.15 }}
                className="w-full p-3 bg-[#FDFDFD] rounded-[12px] border border-[#111111]/10"
              >
                <MarkdownText data={cleanContent} />
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {hasPdf && (
          <div className="mt-3 p-3 bg-[#FFF8FB] rounded-[10px] border border-[#FF187F]/50 flex items-center gap-2">
            <FileText size={24} color="#FF187F" className="shrink-0" />
            <div className="flex-1 flex flex-col">
              <span className="text-black text-[11.5px] font-bold">Business Plan PDF</span>
              <span className="text-gray-500 text-[8.5px]">Saved locally when opened</span>
            </div>
            <button
              onClick={(e) => { e.stopPropagation(); onOpenPdf(); }}
              className="bg-[#FF187F] hover:bg-[#FF187F]/90 text-white px-3 py-2 rounded-lg flex items-center gap-1.5 transition-colors"
            >
              <Download size={14} />
              <span className="text-[10px] font-bold">Open</span>
            </button>
          </div>
        )}
      </div>
    </motion.div>
  );
}

// ---------------------------------
// Helpers
// ---------------------------------

function getAgentColor(agent) {
  switch (agent) {
    case "Orchestrator": return "#FF187F";
    case "Location Scout": return "#111111";
    case "Competitor Analyst": return "#111111";
    case "Business Planner": return "#FF187F";
    default: return "#9CA3AF";
  }
}

function getAgentIcon(agent) {
  switch (agent) {
    case "Orchestrator": return Settings;
    case "Location Scout": return Map;
    case "Competitor Analyst": return BarChart2;
    case "Business Planner": return FileText;
    default: return Bot;
  }
}

function getAgentRoleTag(agent) {
  switch (agent) {
    case "Orchestrator": return "Coordinator";
    case "Location Scout": return "GIS + Bright Data";
    case "Competitor Analyst": return "Market Saturation";
    case "Business Planner": return "Strategy Architect";
    default: return "Agent";
  }
}

function getMessageContentForDisplay(msg) {
  if (!msg?.content) return "";
  return msg.content
    .split('\n')
    .filter(line => {
      const lower = line.toLowerCase();
      return !lower.includes('download link') && !lower.includes('/api/rooms/') && !lower.includes('http://');
    })
    .join('\n')
    .trim();
}

function getMessagePreview(text) {
  const compact = text.replace(/[#*_`>]+/g, '').replace(/\s+/g, ' ').trim();
  if (compact.length <= 220) return compact;
  return `${compact.substring(0, 220).trim()}...`;
}

function ParsedMentions({ text }) {
  if (!text) return null;
  const parts = text.split(/(@Orchestrator|@Location Scout|@Competitor Analyst|@Business Planner)/g);
  
  return (
    <>
      {parts.map((part, i) => {
        if (SUGGESTED_MENTIONS.includes(part)) {
          return (
            <span key={i} className="inline-block px-1.5 py-0.5 mx-0.5 bg-white/10 border border-white/30 rounded-md text-[9.5px] font-extrabold align-middle">
              {part}
            </span>
          );
        }
        return <span key={i}>{part}</span>;
      })}
    </>
  );
}

function DiagnosticsBadge({ diag }) {
  const provider = diag?.provider || 'LLM';
  const model = diag?.model || '';
  const latency = diag?.latency_sec;
  const latencyStr = latency ? `${latency}s` : "";
  const cost = diag?.cost_usd ? parseFloat(diag.cost_usd) : null;
  
  const isFeatherless = provider.toLowerCase().includes('featherless');
  const isAimlapi = provider.toLowerCase().includes('aimlapi') || provider.toLowerCase().includes('ai/ml');

  let bgClass = "bg-[#F8FAFC]";
  let borderClass = "border-[#E2E8F0]";
  let textClass = "text-[#64748B]";

  if (isAimlapi) {
    bgClass = "bg-[#FFF1F2]";
    borderClass = "border-[#FECDD3]";
    textClass = "text-[#E11D48]";
  } else if (isFeatherless) {
    bgClass = "bg-[#F0FDF4]";
    borderClass = "border-[#DCFCE7]";
    textClass = "text-[#15803D]";
  }

  const segments = [provider, model];
  if (latencyStr) segments.push(latencyStr);
  if (!isFeatherless && cost !== null) segments.push(`$${cost.toFixed(4)}`);

  return (
    <div className={`inline-flex items-center px-1.5 py-0.5 rounded-md border-[0.8px] ${bgClass} ${borderClass}`}>
      <Cpu size={8} className={textClass} />
      <span className={`ml-1 font-mono text-[7.2px] font-bold ${textClass} truncate max-w-[200px]`}>
        {segments.join(" | ")}
      </span>
    </div>
  );
}
