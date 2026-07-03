import React from 'react';
import { Settings, Map, BarChart2, FileText, Bot, Loader2, CheckCircle2 } from 'lucide-react';
import { motion } from 'framer-motion';

export default function AgentGraphNode({
  agent,
  title,
  subtitle,
  active,
  done,
  width,
  color,
  icon: IconComponent,
  roleTag
}) {
  const isPending = !active && !done;

  let borderColor = `${color}33`; // 20% opacity
  let bgColor = 'white';
  
  if (active) {
    borderColor = color;
  } else if (done) {
    borderColor = `${color}99`; // 60% opacity
  } else {
    borderColor = '#E2E8F0';
    bgColor = '#F8FAFC';
  }

  return (
    <div 
      className="rounded-[16px] border-[1.5px] p-3 flex flex-col transition-all duration-300 relative"
      style={{
        width: width ? `${width}px` : '100%',
        borderColor,
        backgroundColor: bgColor,
        boxShadow: active ? `0 4px 12px ${color}1a` : '0 2px 4px rgba(0,0,0,0.02)'
      }}
    >
      <div className="flex items-start gap-2">
        <div 
          className="w-7 h-7 rounded-full border flex items-center justify-center shrink-0"
          style={{
            backgroundColor: isPending ? '#F1F5F9' : `${color}14`,
            borderColor: isPending ? '#E2E8F0' : color
          }}
        >
          {IconComponent ? (
            <IconComponent size={14} color={isPending ? '#94A3B8' : color} />
          ) : (
            <Bot size={14} color={isPending ? '#94A3B8' : color} />
          )}
        </div>
        
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-1.5">
            <span className="text-[11px] font-bold truncate text-black">{title}</span>
            {active && (
              <Loader2 size={10} color={color} className="animate-spin shrink-0" />
            )}
            {done && (
              <CheckCircle2 size={10} color={color} className="shrink-0" />
            )}
          </div>
          <span 
            className="text-[8.5px] font-semibold truncate block mt-[1px]"
            style={{ color: isPending ? '#94A3B8' : color }}
          >
            {agent} • {roleTag}
          </span>
          <span className="text-gray-500 text-[8.5px] font-medium leading-[1.2] mt-1 block truncate">
            {subtitle}
          </span>
        </div>
      </div>
      
      {active && (
        <motion.div 
          className="absolute inset-0 rounded-[16px] border-[1.5px] pointer-events-none"
          style={{ borderColor: color }}
          animate={{ opacity: [0, 0.4, 0] }}
          transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
        />
      )}
    </div>
  );
}
