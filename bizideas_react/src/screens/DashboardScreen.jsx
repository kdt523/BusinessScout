import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { RefreshCw, Loader2, History } from 'lucide-react';
import ResponsiveWebWrapper from '../components/ResponsiveWebWrapper';
import HistoryReportCard from '../components/HistoryReportCard';
import ApiService from '../services/apiService';

const SUGGESTED_CITIES = [
  "New York, United States",
  "Tokyo, Japan",
  "Paris, France",
  "Dubai, United Arab Emirates",
];

const SUGGESTED_BUSINESSES = [
  "Coffee Shop",
  "Boutique Retail",
  "Co-working Space"
];

const AGENTS_WORKFLOW = [
  {
    num: "1",
    name: "Orchestrator Agent",
    role: "Coordinator",
    desc: "Creates the room mesh, initiates the brief, and handles participant routing.",
    color: "#FF187F"
  },
  {
    num: "2",
    name: "Location Scout Agent",
    role: "Geographic Scout",
    desc: "Evaluates foot traffic densities, calculates coordinate matrices, and updates maps.",
    color: "#111111"
  },
  {
    num: "3",
    name: "Competitor Analyst Agent",
    role: "Saturation Expert",
    desc: "Gathers local competitor listings and generates comparative feasibility index scoring.",
    color: "#000000"
  },
  {
    num: "4",
    name: "Business Planner Agent",
    role: "Strategic Planner",
    desc: "Models demand seasonality trends and compiles final programmatic PDF consensus report.",
    color: "#111111"
  },
];

export default function DashboardScreen() {
  const navigate = useNavigate();
  const [businessType, setBusinessType] = useState("Coffee Shop");
  const [city, setCity] = useState("New York, United States");
  const [isLoading, setIsLoading] = useState(false);
  const [historyReports, setHistoryReports] = useState([]);
  const [isHistoryLoading, setIsHistoryLoading] = useState(false);

  useEffect(() => {
    loadHistory();
  }, []);

  const loadHistory = async () => {
    setIsHistoryLoading(true);
    try {
      const history = await ApiService.fetchReportsHistory();
      setHistoryReports(history);
    } catch (e) {
      console.error("Error loading history:", e);
    } finally {
      setIsHistoryLoading(false);
    }
  };

  const startAnalysis = async () => {
    if (!businessType.trim() || !city.trim()) {
      alert("Please fill in all fields");
      return;
    }

    setIsLoading(true);
    try {
      // Get browser locale info
      const userLocale = navigator.language;
      const userCountry = userLocale.split('-')[1] || null;

      const roomId = await ApiService.createAnalysisRoom(
        businessType.trim(),
        city.trim(),
        userLocale,
        userCountry
      );

      navigate(`/room/${roomId}`, { 
        state: { businessType: businessType.trim(), city: city.trim() }
      });
    } catch (e) {
      alert(`Failed to start session: ${e.message}`);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <ResponsiveWebWrapper>
      <div className="bg-[#FDFDFD] min-h-screen text-black overflow-y-auto overflow-x-hidden p-6 pb-12">
        <div className="flex flex-col">
          <div className="h-4" />
          
          {/* Header */}
          <motion.div 
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="flex flex-col"
          >
            <span className="text-[#FF187F] text-[13px] font-black tracking-[4px]">
              B SCOUT
            </span>
            <div className="h-1.5" />
            <h1 className="text-black text-[28px] font-extrabold leading-[1.15] tracking-[-0.5px]">
              Multi-Agent Feasibility
            </h1>
            <h1 className="text-[#111111] text-[28px] font-extrabold leading-[1.15] tracking-[-0.5px]">
              Scouting System
            </h1>
            <div className="h-2.5" />
            <p className="text-gray-700 text-[13px] leading-relaxed">
              Launch a collaborative team of specialized AI agents to scout locations, analyze competitor saturation, and compile a strategic business plan.
            </p>
          </motion.div>

          <div className="h-6" />

          {/* Inputs Card */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7 }}
            className="bg-white rounded-[24px] p-[22px] border-[1.5px] border-[#111111]/35 shadow-[0_12px_32px_rgba(17,17,17,0.08)] flex flex-col"
          >
            <label className="text-black text-[13px] font-bold">
              What business are you opening?
            </label>
            <div className="h-2" />
            <input
              type="text"
              value={businessType}
              onChange={(e) => setBusinessType(e.target.value)}
              placeholder="e.g. Specialty Coffee, Coworking Hub"
              className="w-full bg-[#FAF8F5] text-black text-[14px] font-medium px-4 py-3.5 rounded-[12px] border border-[#111111]/25 focus:outline-none focus:border-[#FF187F] focus:ring-1 focus:ring-[#FF187F] transition-all"
            />
            <div className="h-2.5" />
            <div className="flex flex-wrap gap-2">
              {SUGGESTED_BUSINESSES.map(b => (
                <button
                  key={b}
                  onClick={() => setBusinessType(b)}
                  className="bg-white border border-[#111111]/40 rounded-full px-3 py-1 text-[10.5px] font-semibold text-black hover:bg-gray-50 transition-colors"
                >
                  {b}
                </button>
              ))}
            </div>

            <div className="h-5" />

            <label className="text-black text-[13px] font-bold">
              Target Location / City
            </label>
            <div className="h-2" />
            <input
              type="text"
              value={city}
              onChange={(e) => setCity(e.target.value)}
              placeholder="e.g. London, United Kingdom"
              className="w-full bg-[#FAF8F5] text-black text-[14px] font-medium px-4 py-3.5 rounded-[12px] border border-[#111111]/25 focus:outline-none focus:border-[#FF187F] focus:ring-1 focus:ring-[#FF187F] transition-all"
            />
            <div className="h-2.5" />
            <div className="flex flex-wrap gap-2">
              {SUGGESTED_CITIES.map(c => (
                <button
                  key={c}
                  onClick={() => setCity(c)}
                  className="bg-white border border-[#111111]/40 rounded-full px-3 py-1 text-[10.5px] font-semibold text-black hover:bg-gray-50 transition-colors"
                >
                  {c}
                </button>
              ))}
            </div>

            <div className="h-6" />

            <button
              onClick={startAnalysis}
              disabled={isLoading}
              className="w-full h-[50px] rounded-[14px] bg-gradient-to-r from-[#FF187F] to-[#FF187F]/85 shadow-[0_6px_18px_rgba(255,24,127,0.22)] flex items-center justify-center hover:opacity-90 transition-opacity disabled:opacity-70"
            >
              {isLoading ? (
                <Loader2 className="animate-spin text-white w-6 h-6" />
              ) : (
                <span className="text-white text-[14px] font-bold tracking-[0.3px]">
                  Recruit Agents & Start Analysis
                </span>
              )}
            </button>
          </motion.div>

          {/* History Section */}
          {isHistoryLoading && historyReports.length === 0 ? (
            <div className="flex justify-center py-5 mt-5">
              <Loader2 className="animate-spin text-[#FF187F] w-6 h-6" />
            </div>
          ) : historyReports.length > 0 ? (
            <div className="flex flex-col mt-7">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center text-black">
                  <History size={20} />
                  <span className="ml-2 text-[16px] font-bold tracking-[0.2px]">
                    Recent Feasibility Reports
                  </span>
                </div>
                <button 
                  onClick={loadHistory}
                  className="flex items-center text-[#FF187F] hover:bg-[#FF187F]/10 px-2 py-1 rounded"
                >
                  <RefreshCw size={14} className="mr-1" />
                  <span className="text-[12px] font-bold">Refresh</span>
                </button>
              </div>
              <div className="flex flex-col">
                {historyReports.map(item => {
                  const dateObj = new Date(item.timestamp * 1000);
                  const dateStr = dateObj.toLocaleString().split(',')[0] + ' ' + dateObj.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
                  return (
                    <HistoryReportCard
                      key={item.room_id}
                      roomId={item.room_id}
                      businessType={item.business_type}
                      city={item.city}
                      dateStr={dateStr}
                    />
                  );
                })}
              </div>
            </div>
          ) : null}

          <div className="h-7" />

          <h3 className="text-black text-[15px] font-bold tracking-[0.2px] mb-3">
            Multi-Agent Collaboration Loop
          </h3>

          <div className="flex flex-col gap-3">
            {AGENTS_WORKFLOW.map((ag, index) => (
              <motion.div
                key={ag.num}
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: index * 0.15 }}
                className="bg-white rounded-[18px] border border-[#111111]/20 p-4 shadow-[0_4px_12px_rgba(0,0,0,0.015)] flex items-start"
              >
                <div 
                  className="w-[26px] h-[26px] rounded-full border-[1.5px] flex items-center justify-center shrink-0 mt-0.5"
                  style={{ 
                    borderColor: ag.color, 
                    backgroundColor: `${ag.color}14`, // ~8% opacity
                    color: ag.color 
                  }}
                >
                  <span className="text-[11px] font-bold">{ag.num}</span>
                </div>
                <div className="w-3.5" />
                <div className="flex flex-col flex-1">
                  <div className="flex items-center flex-wrap">
                    <span className="text-black text-[12.5px] font-bold">{ag.name}</span>
                    <span className="w-1.5" />
                    <span className="text-gray-600 text-[10px] font-medium">• {ag.role}</span>
                  </div>
                  <div className="h-1" />
                  <span className="text-gray-700 text-[10.5px] leading-[1.4]">
                    {ag.desc}
                  </span>
                </div>
              </motion.div>
            ))}
          </div>

        </div>
      </div>
    </ResponsiveWebWrapper>
  );
}
