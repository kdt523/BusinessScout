import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Play, FileText, ChevronRight, Loader2 } from 'lucide-react';

export default function HistoryReportCard({ roomId, businessType, city, dateStr, onResume }) {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);

  const handleResume = () => {
    setLoading(true);
    // Assuming onResume is a prop or we just navigate
    if (onResume) {
      onResume(roomId, businessType, city);
    } else {
      navigate(`/room/${roomId}`, { state: { businessType, city } });
    }
  };

  return (
    <div className="mb-3 p-4 bg-white rounded-[18px] border border-[#111111]/20 shadow-sm flex flex-col cursor-pointer hover:shadow-md transition-shadow" onClick={handleResume}>
      <div className="flex justify-between items-start mb-3">
        <div className="flex flex-col">
          <span className="text-[12.5px] font-bold text-black">{businessType}</span>
          <span className="text-[10.5px] font-medium text-gray-500 mt-1">{city}</span>
        </div>
        <div className="px-2 py-1 bg-gray-100 rounded-md">
          <span className="text-[9px] font-semibold text-gray-600">{dateStr}</span>
        </div>
      </div>
      
      <div className="flex items-center justify-between mt-1 pt-3 border-t border-gray-100">
        <div className="flex items-center text-[#FF187F]">
          <FileText size={14} className="mr-1.5" />
          <span className="text-[11px] font-bold">View Analysis</span>
        </div>
        <div className="flex items-center text-gray-400">
          {loading ? <Loader2 size={16} className="animate-spin" /> : <ChevronRight size={16} />}
        </div>
      </div>
    </div>
  );
}
