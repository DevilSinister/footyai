using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.Cors;
using Footy_AI.Models;

namespace Footy_AI.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class ProcessingController : ApiController
    {
        [HttpPost]
        public IHttpActionResult IngestMatchSummary(IngestMatchSummaryRequest request)
        {
            if (request == null || request.Match == null)
                return BadRequest("Payload is required.");

            using (var db = new FootballDBEntities())
            {
                try
                {
                    var match = new Match
                    {
                        M_date = request.Match.MDate ?? DateTime.UtcNow,
                        M_location = request.Match.MLocation ?? "Unknown",
                        User_id = request.Match.UserId
                    };
                    db.Match.Add(match);
                    db.SaveChanges();

                    var teamMap = new Dictionary<string, Team>(StringComparer.OrdinalIgnoreCase);
                    if (request.Teams != null)
                    {
                        foreach (var incomingTeam in request.Teams)
                        {
                            if (incomingTeam == null || string.IsNullOrWhiteSpace(incomingTeam.TName))
                                continue;

                            var existing = db.Team.FirstOrDefault(t =>
                                t.T_name.Equals(incomingTeam.TName, StringComparison.OrdinalIgnoreCase));

                            if (existing == null)
                            {
                                existing = new Team { T_name = incomingTeam.TName };
                                db.Team.Add(existing);
                                db.SaveChanges();
                            }

                            if (!string.IsNullOrWhiteSpace(incomingTeam.TId))
                                teamMap[incomingTeam.TId] = existing;
                        }
                    }

                    var playMap = new Dictionary<string, Play>(StringComparer.OrdinalIgnoreCase);
                    if (request.Play != null)
                    {
                        foreach (var incomingPlay in request.Play)
                        {
                            if (incomingPlay == null)
                                continue;

                            Team mappedTeam = null;
                            if (!string.IsNullOrWhiteSpace(incomingPlay.TID))
                                teamMap.TryGetValue(incomingPlay.TID, out mappedTeam);

                            var play = new Play
                            {
                                T_id = mappedTeam?.T_id,
                                M_id = match.M_id,
                                score = incomingPlay.Score
                            };
                            db.Play.Add(play);
                            db.SaveChanges();

                            if (!string.IsNullOrWhiteSpace(incomingPlay.PlId))
                                playMap[incomingPlay.PlId] = play;
                        }
                    }

                    var eventMap = new Dictionary<string, Event>(StringComparer.OrdinalIgnoreCase);
                    if (request.Events != null)
                    {
                        foreach (var incomingEvent in request.Events)
                        {
                            if (incomingEvent == null || string.IsNullOrWhiteSpace(incomingEvent.EventType))
                                continue;

                            var eventEntity = new Event
                            {
                                Event_type = incomingEvent.EventType,
                                Event_name = string.IsNullOrWhiteSpace(incomingEvent.EventName)
                                    ? incomingEvent.EventType
                                    : incomingEvent.EventName,
                                Description = !string.IsNullOrWhiteSpace(incomingEvent.Description)
                                    ? incomingEvent.Description
                                    : incomingEvent.Decription,
                                VideoPath = incomingEvent.ClipPath
                            };
                            var resolvedDescription = !string.IsNullOrWhiteSpace(incomingEvent.Description)
                                ? incomingEvent.Description
                                : incomingEvent.Decription;
                            TrySetStringProperty(eventEntity, "description", resolvedDescription);
                            TrySetStringProperty(eventEntity, "Description", resolvedDescription);
                            TrySetStringProperty(eventEntity, "decription", resolvedDescription);
                            TrySetStringProperty(eventEntity, "Decription", resolvedDescription);
                            TrySetStringProperty(eventEntity, "clip_file_location", incomingEvent.ClipPath);
                            TrySetStringProperty(eventEntity, "ClipFileLocation", incomingEvent.ClipPath);
                            db.Event.Add(eventEntity);
                            db.SaveChanges();

                            if (!string.IsNullOrWhiteSpace(incomingEvent.EId))
                                eventMap[incomingEvent.EId] = eventEntity;
                        }
                    }

                    if (request.OccurBy != null)
                    {
                        var goalCountsByPlayId = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
                        foreach (var incomingOccur in request.OccurBy)
                        {
                            if (incomingOccur == null)
                                continue;

                            Event mappedEvent = null;
                            if (!string.IsNullOrWhiteSpace(incomingOccur.EId))
                                eventMap.TryGetValue(incomingOccur.EId, out mappedEvent);

                            Play mappedPlay = null;
                            if (!string.IsNullOrWhiteSpace(incomingOccur.PlId))
                                playMap.TryGetValue(incomingOccur.PlId, out mappedPlay);

                            int? resolvedPlayerId = incomingOccur.PId;
                            if (!resolvedPlayerId.HasValue && !string.IsNullOrWhiteSpace(incomingOccur.DetectedJerseyNo) && mappedPlay?.T_id != null)
                            {
                                int jerseyNo;
                                if (int.TryParse(incomingOccur.DetectedJerseyNo, NumberStyles.Integer, CultureInfo.InvariantCulture, out jerseyNo))
                                {
                                    var player = db.Player.FirstOrDefault(p => p.T_id == mappedPlay.T_id && p.jersey_no == jerseyNo);
                                    if (player != null)
                                        resolvedPlayerId = player.P_id;
                                }
                            }

                            var occur = new Occur_By
                            {
                                E_id = mappedEvent?.E_id,
                                Pl_id = mappedPlay?.Pl_id,
                                P_id = resolvedPlayerId,
                                start_time = ToTimeSpan(incomingOccur.StartTime),
                                end_time = ToTimeSpan(incomingOccur.EndTime)
                            };
                            db.Occur_By.Add(occur);

                            if (mappedEvent != null &&
                                mappedPlay != null &&
                                !string.IsNullOrWhiteSpace(incomingOccur.PlId) &&
                                string.Equals(mappedEvent.Event_type, "goal", StringComparison.OrdinalIgnoreCase))
                            {
                                goalCountsByPlayId[incomingOccur.PlId] = goalCountsByPlayId.ContainsKey(incomingOccur.PlId)
                                    ? goalCountsByPlayId[incomingOccur.PlId] + 1
                                    : 1;
                            }
                        }

                        foreach (var item in goalCountsByPlayId)
                        {
                            Play play;
                            if (!playMap.TryGetValue(item.Key, out play))
                                continue;

                            var currentScore = play.score ?? 0;
                            if (item.Value > currentScore)
                                play.score = item.Value;
                        }
                    }

                    db.SaveChanges();

                    return Content(HttpStatusCode.Created, new
                    {
                        success = true,
                        message = "Match summary ingested successfully.",
                        matchId = match.M_id
                    });
                }
                catch (Exception ex)
                {
                    return Content(HttpStatusCode.InternalServerError, new
                    {
                        success = false,
                        message = "Failed to ingest match summary.",
                        error = ex.Message
                    });
                }
            }
        }

        [HttpGet]
        public IHttpActionResult GetMatchesByUser(int userId)
        {
            using (var db = new FootballDBEntities())
            {
                db.Configuration.ProxyCreationEnabled = false;
                var matches = db.Match
                    .Where(m => m.User_id == userId)
                    .OrderByDescending(m => m.M_date)
                    .Select(m => new
                    {
                        matchId = m.M_id,
                        matchDate = m.M_date,
                        location = m.M_location,
                        userId = m.User_id
                    })
                    .ToList();

                return Ok(matches);
            }
        }

        [HttpGet]
        public IHttpActionResult GetMatchSummary(int matchId)
        {
            using (var db = new FootballDBEntities())
            {
                db.Configuration.ProxyCreationEnabled = false;

                var match = db.Match.FirstOrDefault(m => m.M_id == matchId);
                if (match == null)
                    return NotFound();

                var plays = db.Play.Where(p => p.M_id == matchId).ToList();
                var playIds = plays.Select(p => p.Pl_id).ToList();
                var occurRows = db.Occur_By.Where(o => o.Pl_id.HasValue && playIds.Contains(o.Pl_id.Value)).ToList();

                var eventIds = occurRows.Where(o => o.E_id.HasValue).Select(o => o.E_id.Value).Distinct().ToList();
                var playerIds = occurRows.Where(o => o.P_id.HasValue).Select(o => o.P_id.Value).Distinct().ToList();
                var teamIds = plays.Where(p => p.T_id.HasValue).Select(p => p.T_id.Value).Distinct().ToList();

                var events = db.Event.Where(e => eventIds.Contains(e.E_id)).ToList();
                var players = db.Player.Where(p => playerIds.Contains(p.P_id)).ToList();
                var teams = db.Team.Where(t => teamIds.Contains(t.T_id)).ToList();

                return Ok(new
                {
                    match = new
                    {
                        matchId = match.M_id,
                        matchDate = match.M_date,
                        location = match.M_location,
                        userId = match.User_id
                    },
                    teams = teams.Select(t => new { teamId = t.T_id, teamName = t.T_name }).ToList(),
                    play = plays.Select(p => new { playId = p.Pl_id, teamId = p.T_id, matchId = p.M_id, score = p.score }).ToList(),
                    events = events.Select(e => new
                    {
                        eventId = e.E_id,
                        eventType = e.Event_type,
                        eventName = e.Event_name,
                        description = e.Description,
                        clipFileLocation = e.VideoPath
                    }).ToList(),
                    occurBy = occurRows.Select(o => new
                    {
                        occurId = o.Occur_id,
                        eventId = o.E_id,
                        playId = o.Pl_id,
                        playerId = o.P_id,
                        startTime = o.start_time,
                        endTime = o.end_time
                    }).ToList(),
                    players = players.Select(p => new
                    {
                        playerId = p.P_id,
                        name = p.P_name,
                        jerseyNo = p.jersey_no,
                        teamId = p.T_id
                    }).ToList()
                });
            }
        }

        private static TimeSpan? ToTimeSpan(double? seconds)
        {
            if (!seconds.HasValue || seconds.Value < 0)
                return null;
            return TimeSpan.FromSeconds(seconds.Value);
        }

        private static string SafeStringProperty(object source, string propertyName)
        {
            if (source == null || string.IsNullOrWhiteSpace(propertyName))
                return null;

            var prop = source.GetType().GetProperty(propertyName);
            if (prop == null)
                return null;

            var value = prop.GetValue(source, null);
            return value?.ToString();
        }

        private static void TrySetStringProperty(object target, string propertyName, string value)
        {
            if (target == null || string.IsNullOrWhiteSpace(propertyName))
                return;

            var prop = target.GetType().GetProperty(propertyName);
            if (prop == null || !prop.CanWrite)
                return;

            prop.SetValue(target, value, null);
        }
    }
}
