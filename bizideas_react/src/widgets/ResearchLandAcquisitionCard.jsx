import React from 'react';
import { Building, Calendar, Home, MapPin } from 'lucide-react';

export default function ResearchLandAcquisitionCard({ landResearch, marketProfile }) {
  if (!landResearch || landResearch.length === 0) return null;

  const currencySymbol = marketProfile?.currency_symbol || '$';

  const formatAmount = (amount) => {
    if (amount >= 1000000) {
      return `${(amount / 1000000).toFixed(1)}M`;
    } else if (amount >= 1000) {
      return `${(amount / 1000).toFixed(0)}K`;
    }
    return amount.toFixed(0);
  };

  return (
    <div className="p-[22px] bg-white rounded-[24px] border border-[#111111]/25 shadow-[0_8px_24px_rgba(0,0,0,0.03)] flex flex-col items-start">
      <div className="flex items-center">
        <div className="p-2 bg-[#111111]/10 rounded-full">
          <Building size={18} color="#111111" />
        </div>
        <span className="ml-2.5 text-[#333333] text-[12.5px] font-black tracking-[1px] uppercase">
          SITE & LAND ACQUISITION
        </span>
      </div>
      
      <div className="h-5" />
      
      <div className="flex flex-col w-full gap-4">
        {landResearch.map((item, idx) => {
          const zoneName = item.zone_name || 'Primary Corridor';
          const decision = item.decision || 'Validation Needed';
          const rent = Number(item.estimated_rent_php_month || 0);
          const buy = Number(item.estimated_land_purchase_php || 0);
          const lat = Number(item.lat || 0);
          const lng = Number(item.lng || 0);
          const source = item.source || 'Bright Data';
          const listingsCount = Array.isArray(item.listings) ? item.listings.length : 0;

          const rentStr = rent > 0 ? `${currencySymbol}${formatAmount(rent)} / mo` : 'N/A';
          const buyStr = buy > 0 ? `${currencySymbol}${formatAmount(buy)}` : 'N/A';

          const isRecommended = decision.toLowerCase().includes('buy') || decision.toLowerCase().includes('lease');
          const badgeColor = isRecommended ? '#10B981' : '#9CA3AF';

          return (
            <div key={idx} className="p-4 bg-[#FAFAFA] rounded-[16px] border border-gray-100 flex flex-col">
              <div className="flex justify-between items-center w-full">
                <span className="text-black text-[14px] font-bold flex-1 truncate">
                  {zoneName}
                </span>
                <div className="px-2 py-1 rounded-[20px] ml-2 shrink-0" style={{ backgroundColor: `${badgeColor}1A` }}>
                  <span className="text-[8.5px] font-black uppercase" style={{ color: badgeColor }}>
                    {decision}
                  </span>
                </div>
              </div>
              
              <div className="h-3.5" />
              
              <div className="flex gap-3 w-full">
                <PriceBox 
                  label="Estimated Lease"
                  price={rentStr}
                  color="#3B82F6"
                  Icon={Calendar}
                />
                <PriceBox 
                  label="Estimated Purchase"
                  price={buyStr}
                  color="#8B5CF6"
                  Icon={Home}
                />
              </div>
              
              <div className="w-full h-[1px] bg-[#EEEEEE] my-3.5" />
              
              <div className="flex justify-between items-center w-full flex-wrap gap-2.5">
                <div className="flex items-center">
                  <MapPin size={13} color="#9CA3AF" />
                  <span className="ml-1 text-gray-700 text-[11px] font-semibold">
                    {lat.toFixed(5)}, {lng.toFixed(5)}
                  </span>
                </div>
                <span className="text-gray-500 text-[10px] font-medium">
                  {listingsCount} listing{listingsCount === 1 ? '' : 's'} verified ({source})
                </span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function PriceBox({ label, price, color, Icon }) {
  return (
    <div className="flex-1 px-3.5 py-3 bg-white rounded-[12px] border shadow-[0_2px_4px_rgba(0,0,0,0.005)] flex flex-col items-start" style={{ borderColor: `${color}20` }}>
      <div className="flex items-center">
        <Icon size={11} color={color} />
        <span className="ml-1 text-[8px] font-extrabold tracking-[0.3px] uppercase truncate" style={{ color: '#6B7280' }}>
          {label}
        </span>
      </div>
      <span className="mt-1.5 text-[16px] font-black truncate w-full" style={{ color }}>
        {price}
      </span>
    </div>
  );
}
