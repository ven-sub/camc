export const newCircuitEventObject = {
  eventDate: null,
  eventType: null,
  eventVenue: null,
  rehearsalDate: null,
  rehearsalTimeStart: null,
  rehearsalTimeEnd: null,
  rehearsalVenue: null,
  rehearsalCalendarSequence: 0,
  rehearsalCalendarUId: null,
  walkThroughTime: null,
  walkThroughTimePM: null,
  includeRehearsalCal: false,
  notes: null, // for the Program's Theme (legacy name)
  coNotes: null,
  branchRep: null,
  fieldInstructor: null,
  sharedCO: null,
  circuit: null,
  circuitSection: [],
  eventLanguage: null,
  deliveryMedium: 'co-located', // default option while we are under COVID restrictions, then 'co-located',
  jwssURL: null, // used for JW Stream Studio Events
  jwssOverseer: null,
  jwssOperator1: null,
  jwssOperator2: null,
  videoConferenceHost: null, // for Zoom
  meetingId: null, // for Zoom
  meetingPassword: null, // for Zoom
  meetingURL: null, // for Zoom
  eventOutlineFiles: [],
  speakerDirectionFiles: [], // not used... can be removed?
  notice317Created: false,
  notice317DateCreated: null,
  // notice317FilePath: '', needed for automated email sending
  auditor: null,
  auditAssignedDate: null,
  auditCompleted: false,
  peakAttendance: null,
  numberBaptized: null,
  report318EventId: null,
  circuitParticipantsOnly: true,
  // April 30 2024 ACO adjustments
  // s318q1: null,
  // s318q2: null,
  // s318q3: null,
  // End ACO Adjustments
  chairmenArray: [],
  routingEventId: null
}
