import express from "express";
import * as admin from "firebase-admin";

const router = express.Router();

interface Location {
  id: string;
  location_name: string;
  latitude: number;
  longitude: number;
  marker_color: number;
  text_color: number;
  created_at: string;
}

interface Event {
  id: string;
  title: string;
  description: string | null;
  image_file: string | null;
  registration_link?: string | null;
  color: number;
  text_color: number;
  day: number;
  time: string;
  location_id: string;
  end_location_id?: string | null;
  room_number: string;
  created_at: string;
}

/**
 * GET /export/events-locations
 * Public endpoint that exports all events and locations as JSON
 * Returns a downloadable JSON file with events and locations data
 */
router.get("/events-locations", async (req, res) => {
  try {
    const db = admin.firestore();

    // Fetch all locations
    const locationsSnapshot = await db.collection("locations").get();
    const locations: Location[] = [];

    locationsSnapshot.forEach((doc) => {
      const data = doc.data();
      locations.push({
        id: doc.id,
        location_name: data.location_name || "",
        latitude: data.latitude || 0,
        longitude: data.longitude || 0,
        marker_color: data.marker_color || 0,
        text_color: data.text_color || 0,
        created_at: data.created_at || "",
      });
    });

    // Fetch all events
    const eventsSnapshot = await db.collection("events").get();
    const events: Event[] = [];

    eventsSnapshot.forEach((doc) => {
      const data = doc.data();
      const event: Event = {
        id: doc.id,
        title: data.title || "",
        description: data.description || null,
        image_file: data.image_file || null,
        color: data.color || 0,
        text_color: data.txtcolor || data.text_color || 0,
        day: data.day || 0,
        time: data.time || "",
        location_id: data.location_id || "",
        room_number: data.room_number || "",
        created_at: data.created_at || "",
      };

      // Add optional fields if they exist
      if (data.registration_link) {
        event.registration_link = data.registration_link;
      }
      if (data.end_location_id) {
        event.end_location_id = data.end_location_id;
      }

      events.push(event);
    });

    // Sort locations and events by created_at
    locations.sort((a, b) => {
      return new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
    });

    events.sort((a, b) => {
      return new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
    });

    // Prepare response data
    const responseData = {
      generated_at: new Date().toISOString(),
      locations_count: locations.length,
      events_count: events.length,
      locations: locations,
      events: events,
    };

    // Set headers to trigger download
    const filename = `events_locations_${new Date().toISOString().split("T")[0]}.json`;
    res.setHeader("Content-Type", "application/json");
    res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);

    // Send pretty-printed JSON response with 2-space indentation
    res.status(200).send(JSON.stringify(responseData, null, 2));
  } catch (error) {
    console.error("Error exporting events and locations:", error);
    res.status(500).json({
      error: "Failed to export events and locations",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

export {router as exportRouter};
