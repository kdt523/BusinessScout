import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'web_iframe_stub.dart'
    if (dart.library.html) 'web_iframe_web.dart';

class MapboxMapWidget extends StatefulWidget {
  final double lat;
  final double lng;
  final String accessToken;
  final String locationName;
  final List<dynamic>? zones;

  const MapboxMapWidget({
    super.key,
    required this.lat,
    required this.lng,
    required this.accessToken,
    required this.locationName,
    this.zones,
  });

  @override
  State<MapboxMapWidget> createState() => _MapboxMapWidgetState();
}

class _MapboxMapWidgetState extends State<MapboxMapWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    
    if (!kIsWeb) {
      final htmlContent = _buildMapHtml();
      
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('[DEBUG MAPBOX]: WebView started loading Mapbox 3D Map...');
            },
            onPageFinished: (String url) {
              print('[DEBUG MAPBOX]: WebView finished loading Mapbox 3D Map');
            },
            onWebResourceError: (WebResourceError error) {
              print('[DEBUG MAPBOX RESOURCE ERROR]: Code: ${error.errorCode}, Description: ${error.description}, URL: ${error.url}');
            },
          ),
        )
        ..addJavaScriptChannel(
          'ConsoleChannel',
          onMessageReceived: (JavaScriptMessage message) {
            print('[MAPBOX JS LOG]: ${message.message}');
          },
        )
        ..loadHtmlString(htmlContent, baseUrl: 'https://api.mapbox.com');
    }
  }

  @override
  void didUpdateWidget(covariant MapboxMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accessToken != oldWidget.accessToken ||
        widget.lat != oldWidget.lat ||
        widget.lng != oldWidget.lng ||
        !listEquals(widget.zones, oldWidget.zones)) {
      if (!kIsWeb && widget.accessToken.isNotEmpty) {
        final htmlContent = _buildMapHtml();
        _controller.loadHtmlString(htmlContent, baseUrl: 'https://api.mapbox.com');
      }
    }
  }

  String _buildMapHtml() {
    final String zonesJson = json.encode(widget.zones ?? []);
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Mapbox 3D Camera Fly-In</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<link href="https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.css" rel="stylesheet" />
<script src="https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.js"></script>
<style>
html, body {
    margin: 0;
    padding: 0;
    width: 100%;
    height: 100%;
    background-color: #FAFAFA;
    overflow: hidden;
}
#map {
    width: 100%;
    height: 100%;
}
/* Premium Store Pin & pulsing ring */
.custom-pin {
    position: relative;
    width: 120px;
    height: 70px;
    display: flex;
    flex-direction: column;
    align-items: center;
}
.pin-label {
    background-color: rgba(17, 17, 17, 0.9);
    color: #fff;
    padding: 4px 8px;
    border-radius: 6px;
    font-size: 10px;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    font-weight: bold;
    border: 1.5px solid #FF187F;
    white-space: nowrap;
    box-shadow: 0 4px 10px rgba(0,0,0,0.2);
    z-index: 2;
    margin-bottom: 4px;
}
.pin-body {
    width: 30px;
    height: 30px;
    background-color: #FF187F;
    border-radius: 50% 50% 50% 0;
    transform: rotate(-45deg);
    box-shadow: 0 4px 10px rgba(255,24,127,0.4);
    border: 2px solid #fff;
    display: flex;
    align-items: center;
    justify-content: center;
    animation: bounce 0.9s infinite alternate;
}
.pin-body svg {
    transform: rotate(45deg);
    fill: white;
    width: 16px;
    height: 16px;
}
@keyframes bounce {
    0% { transform: translateY(0) rotate(-45deg); }
    100% { transform: translateY(-6px) rotate(-45deg); }
}
.pulse-ring {
    position: absolute;
    bottom: 5px; 
    left: 50%;
    transform: translateX(-50%) scale(1);
    width: 24px;
    height: 12px; 
    border: 2px solid #FF187F;
    border-radius: 50%;
    animation: pulse 1.8s infinite ease-out;
    opacity: 0;
    pointer-events: none;
    z-index: -1;
}
@keyframes pulse {
    0% { transform: translateX(-50%) scale(0.5); opacity: 0.8; }
    100% { transform: translateX(-50%) scale(2.5); opacity: 0; }
}
/* Competitor Marker styling */
.competitor-marker {
    width: 12px;
    height: 12px;
    background-color: #1E293B;
    border: 2px solid #FFFFFF;
    border-radius: 50%;
    box-shadow: 0 2px 6px rgba(0,0,0,0.4);
    cursor: pointer;
    transition: transform 0.2s, background-color 0.2s;
}
.competitor-marker:hover {
    background-color: #FF187F;
    transform: scale(1.3);
}
/* Fallback Container styling */
#fallback-container {
    display: none;
    width: 100%;
    height: 100%;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    background-color: #F8F9FA;
    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
    color: #555;
    padding: 12px;
    box-sizing: border-box;
    text-align: center;
}
#fallback-container img {
    max-width: 100%;
    max-height: 80%;
    border-radius: 16px;
    box-shadow: 0 4px 16px rgba(0,0,0,0.08);
    margin-bottom: 8px;
    border: 1px solid rgba(0,0,0,0.05);
}
#fallback-text {
    font-size: 11px;
    color: #666;
    line-height: 1.4;
}
</style>
</head>
<body>
<div id="map"></div>
<div id="fallback-container">
    <img id="fallback-img" src="" alt="Location Map">
    <div id="fallback-text">Loading static map...</div>
</div>

<script>
const logToFlutter = (msg) => {
    if (window.ConsoleChannel && window.ConsoleChannel.postMessage) {
        window.ConsoleChannel.postMessage(typeof msg === 'object' ? JSON.stringify(msg) : String(msg));
    }
};
console.log = logToFlutter;
console.error = logToFlutter;
console.warn = logToFlutter;

window.onerror = function(message, source, lineno, colno, error) {
    logToFlutter("JS ERROR: " + message + " on line " + lineno + " in " + source);
    return false;
};

logToFlutter("HTML loaded. Access token check length: " + ("${widget.accessToken}".length));

const lat = ${widget.lat};
const lng = ${widget.lng};
const accessToken = "${widget.accessToken}";
const locationName = "${widget.locationName.replaceAll("'", "\\'")}";
const zones = ${zonesJson};

// Fallback logic
const showStaticMapFallback = () => {
    logToFlutter("Falling back to Mapbox Static Image...");
    const mapDiv = document.getElementById('map');
    const fallbackDiv = document.getElementById('fallback-container');
    const fallbackImg = document.getElementById('fallback-img');
    const fallbackText = document.getElementById('fallback-text');
    
    mapDiv.style.display = 'none';
    fallbackDiv.style.display = 'flex';
    
    let pins = [];
    if (zones && zones.length > 0) {
        zones.forEach((zone, idx) => {
            const zLat = zone.lat || lat;
            const zLng = zone.lng || lng;
            const color = idx === 0 ? 'ff187f' : '111111';
            pins.push(`pin-l-shop+\${color}(\${zLng},\${zLat})`);
        });
    } else {
        pins.push(`pin-l-shop+ff187f(\${lng},\${lat})`);
    }
    const pinOverlay = pins.join(',');
    
    const width = 600;
    const height = 400;
    const zoom = 14;
    const pitch = 45;
    const bearing = -20;
    
    const staticUrl = `https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/\${pinOverlay}/\${lng},\${lat},\${zoom},\${bearing},\${pitch}/\${width}x\${height}@2x?access_token=\${accessToken}`;
    
    fallbackImg.src = staticUrl;
    fallbackImg.onload = () => {
        logToFlutter("Fallback static map image loaded successfully.");
        fallbackText.innerHTML = `<b>\${locationName}</b><br>Mapbox Static View Active`;
    };
    fallbackImg.onerror = (e) => {
        logToFlutter("Failed to load fallback static map image.");
        fallbackText.innerHTML = `<b>\${locationName}</b><br>Mapbox Static API loading failed.`;
    };
};

if (typeof mapboxgl === 'undefined') {
    logToFlutter("Mapbox GL JS library is undefined. Using static map fallback.");
    showStaticMapFallback();
} else if (!mapboxgl.supported({ failIfMajorPerformanceCaveat: true })) {
    logToFlutter("WebGL is not supported or performs poorly. Using static map fallback.");
    showStaticMapFallback();
} else {
    try {
        logToFlutter("WebGL supported. Initializing Mapbox GL JS Map...");
        mapboxgl.accessToken = accessToken;
        
        // Initialize Mapbox map
        const map = new mapboxgl.Map({
            container: 'map',
            style: 'mapbox://styles/mapbox/streets-v11', 
            center: [lng, lat],
            zoom: 12.5,
            pitch: 0,
            bearing: 0,
            interactive: true,
            attributionControl: false
        });

        // Plot zones and competitors dynamically
        if (zones && zones.length > 0) {
            logToFlutter("Plotting " + zones.length + " zones on Mapbox map...");
            zones.forEach((zone, idx) => {
                const zLat = zone.lat || lat;
                const zLng = zone.lng || lng;
                const isBest = idx === 0;
                const pinColor = isBest ? '#FF187F' : '#111111';
                
                // Create Custom Store Pin HTML Element
                const el = document.createElement('div');
                el.className = 'custom-pin';
                el.innerHTML = `
                    <div class="pin-label">\${idx + 1}. \${zone.name}</div>
                    <div class="pin-body" style="background-color: \${pinColor}; box-shadow: 0 4px 10px \${pinColor}66;">
                        <svg viewBox="0 0 24 24"><path d="M20,4H4v2h16V4z M21,14v-2l-1-5H4L3,12v2c0,1.1,0.9,2,2,2h14C20.1,16,21,15.1,21,14z M12,14H6v-2h6V14z"/></svg>
                    </div>
                    \${isBest ? '<div class="pulse-ring"></div>' : ''}
                `;
                
                new mapboxgl.Marker({ element: el, anchor: 'bottom' })
                    .setLngLat([zLng, zLat])
                    .addTo(map);
                
                // Plot competitors around this zone
                const competitors = zone.competitors || [];
                competitors.forEach((comp, cIdx) => {
                    // Calculate a deterministic offset around the zone coordinates
                    const angle = (cIdx * 2 * Math.PI) / Math.max(1, competitors.length);
                    const radius = 0.0012 + (cIdx * 0.0002); 
                    const cLat = zLat + Math.sin(angle) * radius;
                    const cLng = zLng + Math.cos(angle) * radius;
                    
                    const compEl = document.createElement('div');
                    compEl.className = 'competitor-marker';
                    
                    const popup = new mapboxgl.Popup({ offset: 10 })
                        .setHTML("<div style='font-family:-apple-system,BlinkMacSystemFont,sans-serif;font-size:11px;color:#1E293B;padding:4px;'><b>" + comp.replace(/'/g, "\\'") + "</b><br>Competitor near " + zone.name.replace(/'/g, "\\'") + "</div>");
                    
                    new mapboxgl.Marker({ element: compEl })
                        .setLngLat([cLng, cLat])
                        .setPopup(popup)
                        .addTo(map);
                });
            });
        } else {
            // Fallback for single location
            const el = document.createElement('div');
            el.className = 'custom-pin';
            el.innerHTML = `
                <div class="pin-label">\${locationName}</div>
                <div class="pin-body">
                    <svg viewBox="0 0 24 24"><path d="M20,4H4v2h16V4z M21,14v-2l-1-5H4L3,12v2c0,1.1,0.9,2,2,2h14C20.1,16,21,15.1,21,14z M12,14H6v-2h6V14z"/></svg>
                </div>
                <div class="pulse-ring"></div>
            `;
            
            new mapboxgl.Marker({ element: el, anchor: 'bottom' })
                .setLngLat([lng, lat])
                .addTo(map);
        }

        map.on('load', () => {
            logToFlutter("Map loaded. Queueing 2D-to-3D transition...");
            
            // Add 3D Building Extrusions Layer
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
                        'interpolate',
                        ['linear'],
                        ['zoom'],
                        15,
                        0,
                        15.05,
                        ['get', 'height']
                    ],
                    'fill-extrusion-base': [
                        'interpolate',
                        ['linear'],
                        ['zoom'],
                        15,
                        0,
                        15.05,
                        ['get', 'min_height']
                    ],
                    'fill-extrusion-opacity': 0.65
                }
            });

            // Schedule the smooth 2D-to-3D fly-in transition
            setTimeout(() => {
                logToFlutter("Executing 2D-to-3D flyTo transition...");
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

        map.on('error', (e) => {
            logToFlutter("Mapbox error: " + e.error.message);
        });
        
    } catch (e) {
        logToFlutter("Exception during Mapbox initialization: " + e.message);
        showStaticMapFallback();
    }
}
</script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF111111).withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: kIsWeb
          ? createWebIframe(_buildMapHtml())
          : WebViewWidget(controller: _controller),
    );
  }
}
