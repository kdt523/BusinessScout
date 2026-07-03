import React from 'react';

// Using simple SVG lines instead of complex Flutter custom painters.
// This gives the exact same visual appearance cleanly.

export function SplitBezierConnector({
  activeLeft, activeRight, doneLeft, doneRight, colorLeft, colorRight, colorParent, nodeWidth, label
}) {
  return (
    <div className="w-full flex flex-col items-center my-1 relative h-10">
      <svg className="absolute inset-0 w-full h-full" preserveAspectRatio="none" viewBox="0 0 100 40">
        <path 
          d="M 50 0 C 50 20, 25 20, 25 40" 
          fill="none" 
          stroke={activeLeft || doneLeft ? colorLeft : '#E2E8F0'} 
          strokeWidth="2" 
          strokeDasharray={activeLeft ? '4 4' : 'none'}
        />
        <path 
          d="M 50 0 C 50 20, 75 20, 75 40" 
          fill="none" 
          stroke={activeRight || doneRight ? colorRight : '#E2E8F0'} 
          strokeWidth="2"
          strokeDasharray={activeRight ? '4 4' : 'none'}
        />
        {/* Animated flow dots could be added here if needed */}
      </svg>
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 px-2 py-0.5 bg-white border border-[#E2E8F0] rounded-full z-10">
        <span className="text-[7px] font-bold text-gray-500 tracking-[0.5px]">{label}</span>
      </div>
    </div>
  );
}

export function MergeBezierConnector({
  activeLeft, activeRight, doneLeft, doneRight, parentActive, colorLeft, colorRight, colorParent, nodeWidth, label
}) {
  return (
    <div className="w-full flex flex-col items-center my-1 relative h-10">
      <svg className="absolute inset-0 w-full h-full" preserveAspectRatio="none" viewBox="0 0 100 40">
        <path 
          d="M 25 0 C 25 20, 50 20, 50 40" 
          fill="none" 
          stroke={doneLeft || activeLeft ? colorLeft : '#E2E8F0'} 
          strokeWidth="2"
          strokeDasharray={!doneLeft && activeLeft ? '4 4' : 'none'}
        />
        <path 
          d="M 75 0 C 75 20, 50 20, 50 40" 
          fill="none" 
          stroke={doneRight || activeRight ? colorRight : '#E2E8F0'} 
          strokeWidth="2"
          strokeDasharray={!doneRight && activeRight ? '4 4' : 'none'}
        />
      </svg>
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 px-2 py-0.5 bg-white border border-[#E2E8F0] rounded-full z-10">
        <span className="text-[7px] font-bold text-gray-500 tracking-[0.5px]">{label}</span>
      </div>
    </div>
  );
}

export function StraightBezierConnector({ active, done, color, label }) {
  return (
    <div className="w-full flex flex-col items-center my-1 relative h-8">
      <svg className="absolute inset-0 w-full h-full" preserveAspectRatio="none" viewBox="0 0 100 32">
        <line 
          x1="50" y1="0" x2="50" y2="32" 
          stroke={active || done ? color : '#E2E8F0'} 
          strokeWidth="2"
          strokeDasharray={active ? '4 4' : 'none'}
        />
      </svg>
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 px-2 py-0.5 bg-white border border-[#E2E8F0] rounded-full z-10">
        <span className="text-[7px] font-bold text-gray-500 tracking-[0.5px]">{label}</span>
      </div>
    </div>
  );
}
