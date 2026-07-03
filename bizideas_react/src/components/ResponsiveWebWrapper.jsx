import React from 'react';

export default function ResponsiveWebWrapper({ children }) {
  return (
    <div className="flex justify-center w-full min-h-screen bg-[#F5F5F5]">
      <div className="w-full bg-white shadow-xl relative overflow-hidden">
        {children}
      </div>
    </div>
  );
}
