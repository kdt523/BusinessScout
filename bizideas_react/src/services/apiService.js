const baseUrl = 'http://localhost:8001';

class ApiService {
  static baseUrl = baseUrl;
  static _mapboxAccessToken = null;

  static async getMapboxAccessToken() {
    if (this._mapboxAccessToken) return this._mapboxAccessToken;
    try {
      const response = await fetch(`${baseUrl}/api/config/mapbox`);
      if (response.ok) {
        const data = await response.json();
        this._mapboxAccessToken = data.accessToken;
        return this._mapboxAccessToken || '';
      }
    } catch (e) {
      console.error('Error fetching Mapbox token:', e);
    }
    return '';
  }

  static async createAnalysisRoom(businessType, city, userLocale = null, userCountry = null) {
    const response = await fetch(`${baseUrl}/api/rooms/create`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        business_type: businessType,
        city: city,
        user_locale: userLocale,
        user_country: userCountry,
      }),
    });

    if (response.ok) {
      const data = await response.json();
      return data.room_id;
    } else {
      throw new Error(`Failed to initiate agent room: ${response.status}`);
    }
  }

  static streamRoomMessages(roomId, onMessage, onError, onComplete) {
    const eventSource = new EventSource(`${baseUrl}/api/rooms/${roomId}/stream`);

    eventSource.onmessage = (event) => {
      try {
        if (event.data) {
          const message = JSON.parse(event.data);
          onMessage(message);
        }
      } catch (e) {
        console.warn('SSE parse warning:', e);
      }
    };

    eventSource.onerror = (err) => {
      onError(err);
      eventSource.close();
    };

    // Fastapi doesn't have an explicit 'end' event standard out of the box unless we send one.
    // We rely on the caller to unmount or close the stream.
    return () => {
      eventSource.close();
      if (onComplete) onComplete();
    };
  }

  static getPdfDownloadUrl(roomId) {
    return `${baseUrl}/api/rooms/${roomId}/pdf`;
  }

  static async fetchReportsHistory() {
    const response = await fetch(`${baseUrl}/api/reports`);
    if (response.ok) {
      return await response.json();
    } else {
      throw new Error(`Failed to fetch reports history: ${response.status}`);
    }
  }

  static async getOpportunityIndex(roomId) {
    try {
      const response = await fetch(`${baseUrl}/api/rooms/${roomId}/opportunity_index`);
      if (response.ok) {
        const data = await response.json();
        const opportunityIndex = data.opportunity_index;
        if (typeof opportunityIndex === 'number') {
          return opportunityIndex;
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      console.error('Error fetching opportunity index:', e);
      return null;
    }
  }

  static async getRoomMessages(roomId) {
    const response = await fetch(`${baseUrl}/api/rooms/${roomId}/messages`);
    if (response.ok) {
      return await response.json();
    } else {
      throw new Error(`Failed to fetch room messages: ${response.status}`);
    }
  }

  static async sendRoomMessage(roomId, sender, role, content) {
    try {
      const response = await fetch(`${baseUrl}/api/rooms/${roomId}/messages`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          sender: sender,
          role: role,
          content: content,
          type: 'text',
          data: {},
        }),
      });
      return response.ok;
    } catch (e) {
      console.error('Error sending room message:', e);
      return false;
    }
  }
}

export default ApiService;
