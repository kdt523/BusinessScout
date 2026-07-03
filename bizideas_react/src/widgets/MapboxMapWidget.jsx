import React, { useEffect, useRef, useState } from 'react';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';

export default function MapboxMapWidget({ lat, lng, accessToken, locationName, zones }) {
  const mapContainer = useRef(null);
  const mapRef = useRef(null);
  const [mapLoaded, setMapLoaded] = useState(false);
  const [error, setError] = useState(false);

  useEffect(() => {
    if (!accessToken) {
      setError(true);
      return;
    }

    if (!mapboxgl.supported()) {
      setError(true);
      return;
    }

    try {
      mapboxgl.accessToken = accessToken;

      const map = new mapboxgl.Map({
        container: mapContainer.current,
        style: 'mapbox://styles/mapbox/streets-v11',
        center: [lng, lat],
        zoom: 12.5,
        pitch: 0,
        bearing: 0,
        interactive: true,
        attributionControl: false
      });

      mapRef.current = map;

      map.on('load', () => {
        setMapLoaded(true);

        // Add 3D Buildings
        map.addLayer({
          'id': '3d-buildings',
          'source': 'composite',
          'source-layer': 'building',
          'filter': ['==', 'extrude', 'true'],
          'type': 'fill-extrusion',
          'minzoom': 14,
          'paint': {
            'fill-extrusion-color': '#CCCCCC',
            'fill-extrusion-height': [
              'interpolate', ['linear'], ['zoom'],
              15, 0,
              15.05, ['get', 'height']
            ],
            'fill-extrusion-base': [
              'interpolate', ['linear'], ['zoom'],
              15, 0,
              15.05, ['get', 'min_height']
            ],
            'fill-extrusion-opacity': 0.65
          }
        });

        // Add markers
        if (zones && zones.length > 0) {
          zones.forEach((zone, idx) => {
            const zLat = zone.lat || lat;
            const zLng = zone.lng || lng;
            const isBest = idx === 0;
            const pinColor = isBest ? '#FF187F' : '#111111';

            // Main Pin
            const el = document.createElement('div');
            el.className = 'custom-pin';
            el.innerHTML = `
              <div style="background-color: rgba(17,17,17,0.9); color: #fff; padding: 4px 8px; border-radius: 6px; font-size: 10px; font-weight: bold; border: 1.5px solid #FF187F; white-space: nowrap; margin-bottom: 4px; box-shadow: 0 4px 10px rgba(0,0,0,0.2); z-index: 2; position: relative;">
                ${idx + 1}. ${zone.name}
              </div>
              <div style="width: 30px; height: 30px; background-color: ${pinColor}; border-radius: 50% 50% 50% 0; transform: rotate(-45deg); box-shadow: 0 4px 10px ${pinColor}66; border: 2px solid #fff; display: flex; align-items: center; justify-content: center; position: relative; z-index: 1;">
                <svg viewBox="0 0 24 24" style="transform: rotate(45deg); fill: white; width: 16px; height: 16px;"><path d="M20,4H4v2h16V4z M21,14v-2l-1-5H4L3,12v2c0,1.1,0.9,2,2,2h14C20.1,16,21,15.1,21,14z M12,14H6v-2h6V14z"/></svg>
              </div>
              ${isBest ? `<div style="position: absolute; bottom: 5px; left: 50%; transform: translateX(-50%); width: 24px; height: 12px; border: 2px solid #FF187F; border-radius: 50%; opacity: 0; pointer-events: none; z-index: 0; animation: pulse 1.8s infinite ease-out;"></div>` : ''}
            `;

            new mapboxgl.Marker({ element: el, anchor: 'bottom' })
              .setLngLat([zLng, zLat])
              .addTo(map);

            // Competitors
            const competitors = zone.competitors || [];
            competitors.forEach((comp, cIdx) => {
              const angle = (cIdx * 2 * Math.PI) / Math.max(1, competitors.length);
              const radius = 0.0012 + (cIdx * 0.0002);
              const cLat = zLat + Math.sin(angle) * radius;
              const cLng = zLng + Math.cos(angle) * radius;

              const compEl = document.createElement('div');
              compEl.style.width = '12px';
              compEl.style.height = '12px';
              compEl.style.backgroundColor = '#1E293B';
              compEl.style.border = '2px solid #FFFFFF';
              compEl.style.borderRadius = '50%';
              compEl.style.boxShadow = '0 2px 6px rgba(0,0,0,0.4)';
              compEl.style.cursor = 'pointer';

              const popup = new mapboxgl.Popup({ offset: 10 })
                .setHTML(`<div style="font-size:11px;color:#1E293B;padding:4px;"><b>${comp}</b><br>Competitor near ${zone.name}</div>`);

              new mapboxgl.Marker({ element: compEl })
                .setLngLat([cLng, cLat])
                .setPopup(popup)
                .addTo(map);
            });
          });
        } else {
          // Fallback single pin
          const el = document.createElement('div');
          el.className = 'custom-pin';
          el.innerHTML = `
            <div style="background-color: rgba(17,17,17,0.9); color: #fff; padding: 4px 8px; border-radius: 6px; font-size: 10px; font-weight: bold; border: 1.5px solid #FF187F; white-space: nowrap; margin-bottom: 4px; box-shadow: 0 4px 10px rgba(0,0,0,0.2); z-index: 2; position: relative;">
              ${locationName}
            </div>
            <div style="width: 30px; height: 30px; background-color: #FF187F; border-radius: 50% 50% 50% 0; transform: rotate(-45deg); box-shadow: 0 4px 10px rgba(255,24,127,0.4); border: 2px solid #fff; display: flex; align-items: center; justify-content: center; position: relative; z-index: 1;">
              <svg viewBox="0 0 24 24" style="transform: rotate(45deg); fill: white; width: 16px; height: 16px;"><path d="M20,4H4v2h16V4z M21,14v-2l-1-5H4L3,12v2c0,1.1,0.9,2,2,2h14C20.1,16,21,15.1,21,14z M12,14H6v-2h6V14z"/></svg>
            </div>
          `;

          new mapboxgl.Marker({ element: el, anchor: 'bottom' })
            .setLngLat([lng, lat])
            .addTo(map);
        }

        // Fly to 3D
        setTimeout(() => {
          map.flyTo({
            center: [lng, lat],
            zoom: 16.5,
            pitch: 60,
            bearing: -35,
            duration: 5500,
            essential: true
          });
        }, 1500);
      });

      map.on('error', () => {
        setError(true);
      });

    } catch (e) {
      console.error(e);
      setError(true);
    }

    return () => {
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, [lat, lng, accessToken, locationName, zones]);

  // Handle pulse animation using style tags
  useEffect(() => {
    const style = document.createElement('style');
    style.innerHTML = `
      @keyframes pulse {
        0% { transform: translateX(-50%) scale(0.5); opacity: 0.8; }
        100% { transform: translateX(-50%) scale(2.5); opacity: 0; }
      }
      .custom-pin { display: flex; flex-direction: column; align-items: center; position: relative; width: 120px; height: 70px; }
    `;
    document.head.appendChild(style);
    return () => document.head.removeChild(style);
  }, []);

  return (
    <div className="h-[280px] w-full bg-white rounded-[24px] border-[1.5px] border-[#111111]/15 shadow-[0_8px_24px_rgba(0,0,0,0.04)] overflow-hidden relative">
      <div ref={mapContainer} className="w-full h-full" style={{ display: error ? 'none' : 'block' }} />
      {error && (
        <div className="w-full h-full flex flex-col items-center justify-center bg-[#F8F9FA] p-4 text-center">
          {/* Static map fallback would go here, but for now just show a nice error state */}
          <span className="text-[12px] font-bold text-gray-700">{locationName}</span>
          <span className="text-[10px] text-gray-500 mt-1">Mapbox could not be loaded. Please check your mapbox token or network.</span>
        </div>
      )}
    </div>
  );
}
