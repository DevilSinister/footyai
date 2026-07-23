using System;
using System.Collections.Generic;

namespace Footy_AI.Models
{
    public class IngestMatchSummaryRequest
    {
        public MatchPayload Match { get; set; }
        public List<TeamPayload> Teams { get; set; }
        public List<PlayPayload> Play { get; set; }
        public List<EventPayload> Events { get; set; }
        public List<OccurByPayload> OccurBy { get; set; }
    }

    public class MatchPayload
    {
        public string MId { get; set; }
        public DateTime? MDate { get; set; }
        public string MLocation { get; set; }
        public string VideoPath { get; set; }
        public int? Fps { get; set; }
        public int? Width { get; set; }
        public int? Height { get; set; }
        public int? ProcessedFrames { get; set; }
        public int? UserId { get; set; }
    }

    public class TeamPayload
    {
        public string TId { get; set; }
        public string TName { get; set; }
    }

    public class PlayPayload
    {
        public string PlId { get; set; }
        public string TID { get; set; }
        public string MID { get; set; }
        public int? Score { get; set; }
    }

    public class EventPayload
    {
        public string EId { get; set; }
        public string EventType { get; set; }
        public string EventName { get; set; }
        public string Description { get; set; }
        public string Decription { get; set; }
        public double? Confidence { get; set; }
        public string Reason { get; set; }
        public int? FrameNum { get; set; }
        public double? TimeSec { get; set; }
        public string ClipPath { get; set; }
    }

    public class OccurByPayload
    {
        public string EId { get; set; }
        public string PlId { get; set; }
        public int? PId { get; set; }
        public string PlayerLookupId { get; set; }
        public int? DetectedPlayerTrackId { get; set; }
        public string DetectedJerseyNo { get; set; }
        public double? StartTime { get; set; }
        public double? EndTime { get; set; }
    }
}
