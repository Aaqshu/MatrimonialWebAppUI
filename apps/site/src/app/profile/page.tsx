'use client';

import { useEffect, useMemo, useState } from 'react';
import api from '@/lib/api';
import {
  HeartHandshake, ChevronLeft, ChevronRight, Check, Loader2, User, Landmark,
  GraduationCap, Briefcase, Users, UtensilsCrossed, MapPin, FileText, Cake,
  Ruler, Weight, Droplet, PartyPopper, Sparkles,
} from 'lucide-react';

const TENANT_DB = 'provision-test_provisiontestmatrimony';

/* ---------------------------------- types --------------------------------- */

interface ProfileSection {
  Gender: string; DateOfBirth: string; Height: string; Weight: string;
  MaritalStatus: string; BloodGroup: string; AboutMe: string;
  Religion: string; Caste: string; SubCaste: string; Sect: string; MotherTongue: string;
}
interface EducationSection {
  Qualification: string; College: string; University: string; PassingYear: string; EducationType: string;
}
interface OccupationSection {
  Occupation: string; CompanyName: string; Designation: string; AnnualIncome: string; WorkLocation: string;
}
interface FamilySection {
  FamilyType: string; FamilyStatus: string; FatherName: string; FatherOccupation: string;
  MotherName: string; MotherOccupation: string; Brothers: string; Sisters: string;
}
interface LifestyleSection {
  Diet: string; Smoking: boolean; Drinking: boolean; Hobbies: string; LanguagesKnown: string;
}
interface LocationSection {
  Country: string; State: string; City: string; Address: string; Pincode: string;
}
interface PreferencesSection {
  MinAge: string; MaxAge: string; MinHeight: string; MaxHeight: string;
  Religion: string; Caste: string; Education: string; Occupation: string;
  Country: string; State: string; City: string;
}

interface WizardState {
  profile: ProfileSection;
  education: EducationSection;
  occupation: OccupationSection;
  family: FamilySection;
  lifestyle: LifestyleSection;
  location: LocationSection;
  preferences: PreferencesSection;
}

const emptyState: WizardState = {
  profile: { Gender: '', DateOfBirth: '', Height: '', Weight: '', MaritalStatus: '', BloodGroup: '', AboutMe: '', Religion: '', Caste: '', SubCaste: '', Sect: '', MotherTongue: '' },
  education: { Qualification: '', College: '', University: '', PassingYear: '', EducationType: '' },
  occupation: { Occupation: '', CompanyName: '', Designation: '', AnnualIncome: '', WorkLocation: '' },
  family: { FamilyType: '', FamilyStatus: '', FatherName: '', FatherOccupation: '', MotherName: '', MotherOccupation: '', Brothers: '', Sisters: '' },
  lifestyle: { Diet: '', Smoking: false, Drinking: false, Hobbies: '', LanguagesKnown: '' },
  location: { Country: '', State: '', City: '', Address: '', Pincode: '' },
  preferences: { MinAge: '', MaxAge: '', MinHeight: '', MaxHeight: '', Religion: '', Caste: '', Education: '', Occupation: '', Country: '', State: '', City: '' },
};

/* ------------------------------- step config ------------------------------ */

const STEPS = [
  { key: 'basic', label: 'Basic', icon: User },
  { key: 'community', label: 'Religion', icon: Landmark },
  { key: 'career', label: 'Career', icon: GraduationCap },
  { key: 'family', label: 'Family', icon: Users },
  { key: 'location', label: 'Location', icon: MapPin },
  { key: 'about', label: 'About', icon: FileText },
] as const;

/** Fields counted toward overall completion (booleans excluded — always have a value). */
const COMPLETION_FIELDS: Array<[keyof WizardState, string]> = [
  ['profile', 'Gender'], ['profile', 'DateOfBirth'], ['profile', 'Height'], ['profile', 'Weight'],
  ['profile', 'MaritalStatus'], ['profile', 'BloodGroup'],
  ['profile', 'Religion'], ['profile', 'Caste'], ['profile', 'MotherTongue'],
  ['education', 'Qualification'], ['education', 'PassingYear'],
  ['occupation', 'Occupation'], ['occupation', 'WorkLocation'],
  ['family', 'FamilyType'], ['family', 'FatherName'], ['family', 'MotherName'],
  ['lifestyle', 'Diet'], ['lifestyle', 'Hobbies'], ['lifestyle', 'LanguagesKnown'],
  ['location', 'Country'], ['location', 'State'], ['location', 'City'],
  ['profile', 'AboutMe'],
];

/* ------------------------------- suggestions ------------------------------- */

const RELIGIONS = ['Islam', 'Hindu', 'Christian', 'Sikh', 'Buddhist', 'Jain', 'Other'];
const SECTS = ['Sunni', 'Shia', 'Ahle Hadith', 'Ahmadiyya', 'Barelvi', 'Deobandi', 'Other'];
const QUALIFICATIONS = ['High School', "Bachelor's Degree", "Master's Degree", 'MBA', 'PhD', 'Diploma', 'Other'];
const OCCUPATIONS = ['Software Engineer', 'Doctor', 'Teacher', 'Business Owner', 'Government Employee', 'Engineer', 'Homemaker', 'Other'];

/* ---------------------------------- utils ---------------------------------- */

function calcAge(dob: string): number | null {
  if (!dob) return null;
  const d = new Date(dob);
  if (Number.isNaN(d.getTime())) return null;
  const diff = Date.now() - d.getTime();
  return Math.floor(diff / (365.25 * 24 * 60 * 60 * 1000));
}

function toArray(csv: string): string[] {
  return csv.split(',').map(s => s.trim()).filter(Boolean);
}

function fromArray(arr: unknown): string {
  return Array.isArray(arr) ? arr.join(', ') : (typeof arr === 'string' ? arr : '');
}

function str(v: unknown): string {
  if (v === null || v === undefined) return '';
  return String(v);
}

/* ================================ page ==================================== */

export default function ProfileBuilderPage() {
  const [ready, setReady] = useState(false);
  const [profileExists, setProfileExists] = useState(false);
  const [step, setStep] = useState(0);
  const [data, setData] = useState<WizardState>(emptyState);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [done, setDone] = useState(false);
  const [savedStep, setSavedStep] = useState<number | null>(null);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!localStorage.getItem('site_token')) {
      window.location.href = '/';
      return;
    }
    (async () => {
      try {
        const { data: p } = await api.get(`/site/profile/${TENANT_DB}`);
        setProfileExists(true);
        setData(prev => ({
          profile: { ...prev.profile, ...(p.profile ?? p), AboutMe: str((p.profile ?? p).AboutMe) },
          education: { ...prev.education, ...(p.education ?? {}) },
          occupation: { ...prev.occupation, ...(p.occupation ?? {}) },
          family: { ...prev.family, ...(p.family ?? {}) },
          lifestyle: { ...prev.lifestyle, ...(p.lifestyle ?? {}) },
          location: { ...prev.location, ...(p.location ?? {}) },
          preferences: prev.preferences,
        }));
      } catch (e: any) {
        if (e.response?.status !== 404) {
          setError('Could not load your profile. You can still fill it in below.');
        }
      }
      try {
        const { data: prefs } = await api.get(`/site/profile/${TENANT_DB}/preferences`);
        if (prefs) {
          setData(prev => ({
            ...prev,
            preferences: {
              MinAge: str(prefs.MinAge), MaxAge: str(prefs.MaxAge),
              MinHeight: str(prefs.MinHeight), MaxHeight: str(prefs.MaxHeight),
              Religion: fromArray(prefs.Religion), Caste: fromArray(prefs.Caste),
              Education: fromArray(prefs.Education), Occupation: fromArray(prefs.Occupation),
              Country: str(prefs.Country), State: str(prefs.State), City: str(prefs.City),
            },
          }));
        }
      } catch { /* no preferences saved yet — fine */ }
      setReady(true);
    })();
  }, []);

  const completion = useMemo(() => {
    const filled = COMPLETION_FIELDS.filter(([section, field]) => {
      const v = (data[section] as any)[field];
      return typeof v === 'string' && v.trim().length > 0;
    }).length;
    return Math.round((filled / COMPLETION_FIELDS.length) * 100);
  }, [data]);

  const age = calcAge(data.profile.DateOfBirth);

  function set<K extends keyof WizardState>(section: K, patch: Partial<WizardState[K]>) {
    setData(prev => ({ ...prev, [section]: { ...prev[section], ...patch } }));
  }

  async function saveSection(sectionKey: keyof WizardState, payload: object) {
    setSaving(true); setError('');
    try {
      const method = profileExists ? 'patch' : 'post';
      await api[method](`/site/profile/${TENANT_DB}`, { [sectionKey]: payload });
      setProfileExists(true);
      setSavedStep(step);
      setTimeout(() => setSavedStep(s => (s === step ? null : s)), 1800);
      return true;
    } catch (e: any) {
      setError(e.response?.data?.message || 'Could not save this step. Please try again.');
      return false;
    } finally {
      setSaving(false);
    }
  }

  async function handleNext() {
    let ok = true;
    if (step === 0) ok = await saveSection('profile', { Gender: data.profile.Gender, DateOfBirth: data.profile.DateOfBirth, Height: data.profile.Height, Weight: data.profile.Weight, MaritalStatus: data.profile.MaritalStatus, BloodGroup: data.profile.BloodGroup });
    else if (step === 1) ok = await saveSection('profile', { Religion: data.profile.Religion, Caste: data.profile.Caste, SubCaste: data.profile.SubCaste, Sect: data.profile.Sect, MotherTongue: data.profile.MotherTongue });
    else if (step === 2) {
      ok = await saveSection('education', data.education);
      if (ok) ok = await saveSection('occupation', data.occupation);
    } else if (step === 3) {
      ok = await saveSection('family', data.family);
      if (ok) ok = await saveSection('lifestyle', data.lifestyle);
    } else if (step === 4) {
      ok = await saveSection('location', data.location);
      if (ok) {
        const prefs = data.preferences;
        ok = await saveSection('preferences', {
          MinAge: prefs.MinAge, MaxAge: prefs.MaxAge, MinHeight: prefs.MinHeight, MaxHeight: prefs.MaxHeight,
          Religion: toArray(prefs.Religion), Caste: toArray(prefs.Caste),
          Education: toArray(prefs.Education), Occupation: toArray(prefs.Occupation),
          Country: prefs.Country, State: prefs.State, City: prefs.City,
        });
      }
    }
    if (ok && step < STEPS.length - 1) setStep(s => s + 1);
  }

  async function handleFinish() {
    const ok = await saveSection('profile', { AboutMe: data.profile.AboutMe });
    if (ok) setDone(true);
  }

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background text-white/50">
        <Loader2 className="size-5 animate-spin" />
      </div>
    );
  }

  if (done) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background px-6 text-center text-white">
        <div className="max-w-sm">
          <div className="mx-auto flex size-16 items-center justify-center rounded-2xl bg-emerald-500/15 text-emerald-400">
            <PartyPopper className="size-8" />
          </div>
          <h1 className="mt-6 text-2xl font-semibold tracking-tight">Profile complete!</h1>
          <p className="mt-2 text-sm text-white/50">
            Your matrimonial profile is ready. We&apos;ll start finding thoughtful matches for you.
          </p>
          <a
            href="/dashboard"
            className="mt-8 inline-flex w-full cursor-pointer items-center justify-center rounded-lg bg-emerald-500 py-2.5 font-medium text-emerald-950 transition-colors duration-150 hover:bg-emerald-400"
          >
            Go to dashboard
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background text-white">
      <nav className="flex items-center justify-between border-b border-white/8 px-6 py-4">
        <a href="/dashboard" className="flex items-center gap-2">
          <div className="flex size-8 items-center justify-center rounded-lg bg-emerald-500 text-emerald-950">
            <HeartHandshake className="size-4.5" />
          </div>
          <span className="font-semibold">Matrimony</span>
        </a>
        <span className="text-sm text-white/40">Profile builder</span>
      </nav>

      <div className="mx-auto max-w-3xl px-6 py-10">
        <Stepper step={step} onJump={i => i < step && setStep(i)} />

        <div className="mt-8 rounded-2xl border border-white/10 bg-white/[0.04] p-8 shadow-2xl shadow-black/40 backdrop-blur-md">
          {step === 0 && (
            <div>
              <StepHeader title="The basics" subtitle="Tell us a little about yourself" />
              <div className="mb-8 flex items-center gap-5 rounded-xl border border-white/8 bg-white/[0.02] p-5">
                <CompletionRing percent={completion} />
                <div>
                  <p className="text-sm font-medium text-white/80">Profile completeness</p>
                  <p className="mt-0.5 text-xs text-white/45">Fill in more details across all steps to improve your match quality.</p>
                </div>
              </div>

              <Field label="Gender" required>
                <PillGroup
                  value={data.profile.Gender}
                  onChange={v => set('profile', { Gender: v })}
                  options={[{ value: 'male', label: 'Male' }, { value: 'female', label: 'Female' }, { value: 'other', label: 'Other' }]}
                />
              </Field>

              <div className="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-2">
                <Field label="Date of birth" required icon={Cake} hint={age !== null ? `${age} years old` : undefined}>
                  <input
                    type="date"
                    value={data.profile.DateOfBirth}
                    onChange={e => set('profile', { DateOfBirth: e.target.value })}
                    max={new Date().toISOString().slice(0, 10)}
                    className={inputCls}
                  />
                </Field>
                <Field label="Blood group" icon={Droplet}>
                  <PillGroup
                    value={data.profile.BloodGroup}
                    onChange={v => set('profile', { BloodGroup: v })}
                    options={['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map(v => ({ value: v, label: v }))}
                    columns={4}
                  />
                </Field>
              </div>

              <div className="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-2">
                <Field label="Height (cm)" required icon={Ruler}>
                  <input
                    type="number" min={100} max={250} placeholder="e.g. 172"
                    value={data.profile.Height}
                    onChange={e => set('profile', { Height: e.target.value })}
                    className={inputCls}
                  />
                </Field>
                <Field label="Weight (kg)" icon={Weight}>
                  <input
                    type="number" min={30} max={250} placeholder="e.g. 65"
                    value={data.profile.Weight}
                    onChange={e => set('profile', { Weight: e.target.value })}
                    className={inputCls}
                  />
                </Field>
              </div>

              <Field label="Marital status" required className="mt-5">
                <PillGroup
                  value={data.profile.MaritalStatus}
                  onChange={v => set('profile', { MaritalStatus: v })}
                  options={[
                    { value: 'never_married', label: 'Never Married' },
                    { value: 'divorced', label: 'Divorced' },
                    { value: 'widowed', label: 'Widowed' },
                    { value: 'awaiting_divorce', label: 'Awaiting Divorce' },
                  ]}
                  columns={2}
                />
              </Field>
            </div>
          )}

          {step === 1 && (
            <div>
              <StepHeader title="Religion & community" subtitle="Help us match you within your community preferences" />
              <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
                <Field label="Religion" required>
                  <input list="religions" value={data.profile.Religion} onChange={e => set('profile', { Religion: e.target.value })} placeholder="e.g. Islam" className={inputCls} />
                  <datalist id="religions">{RELIGIONS.map(r => <option key={r} value={r} />)}</datalist>
                </Field>
                <Field label="Sect">
                  <input list="sects" value={data.profile.Sect} onChange={e => set('profile', { Sect: e.target.value })} placeholder="e.g. Sunni" className={inputCls} />
                  <datalist id="sects">{SECTS.map(s => <option key={s} value={s} />)}</datalist>
                </Field>
                <Field label="Caste / Biradari" required>
                  <input value={data.profile.Caste} onChange={e => set('profile', { Caste: e.target.value })} placeholder="e.g. Sheikh" className={inputCls} />
                </Field>
                <Field label="Sub-caste">
                  <input value={data.profile.SubCaste} onChange={e => set('profile', { SubCaste: e.target.value })} className={inputCls} />
                </Field>
                <Field label="Mother tongue" required>
                  <input value={data.profile.MotherTongue} onChange={e => set('profile', { MotherTongue: e.target.value })} placeholder="e.g. Urdu" className={inputCls} />
                </Field>
              </div>
            </div>
          )}

          {step === 2 && (
            <div>
              <StepHeader title="Education & career" subtitle="Share your academic and professional background" />
              <p className="mb-3 flex items-center gap-1.5 text-xs font-medium uppercase tracking-wide text-white/40">
                <GraduationCap className="size-3.5" /> Education
              </p>
              <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
                <Field label="Qualification" required>
                  <input list="qualifications" value={data.education.Qualification} onChange={e => set('education', { Qualification: e.target.value })} placeholder="e.g. Master's Degree" className={inputCls} />
                  <datalist id="qualifications">{QUALIFICATIONS.map(q => <option key={q} value={q} />)}</datalist>
                </Field>
                <Field label="Education type">
                  <PillGroup
                    value={data.education.EducationType}
                    onChange={v => set('education', { EducationType: v })}
                    options={[{ value: 'full_time', label: 'Full Time' }, { value: 'part_time', label: 'Part Time' }, { value: 'distance', label: 'Distance' }]}
                  />
                </Field>
                <Field label="College"><input value={data.education.College} onChange={e => set('education', { College: e.target.value })} className={inputCls} /></Field>
                <Field label="University"><input value={data.education.University} onChange={e => set('education', { University: e.target.value })} className={inputCls} /></Field>
                <Field label="Passing year"><input type="number" min={1970} max={2035} value={data.education.PassingYear} onChange={e => set('education', { PassingYear: e.target.value })} className={inputCls} /></Field>
              </div>

              <p className="mb-3 mt-7 flex items-center gap-1.5 text-xs font-medium uppercase tracking-wide text-white/40">
                <Briefcase className="size-3.5" /> Occupation
              </p>
              <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
                <Field label="Occupation" required>
                  <input list="occupations" value={data.occupation.Occupation} onChange={e => set('occupation', { Occupation: e.target.value })} placeholder="e.g. Software Engineer" className={inputCls} />
                  <datalist id="occupations">{OCCUPATIONS.map(o => <option key={o} value={o} />)}</datalist>
                </Field>
                <Field label="Designation"><input value={data.occupation.Designation} onChange={e => set('occupation', { Designation: e.target.value })} className={inputCls} /></Field>
                <Field label="Company name"><input value={data.occupation.CompanyName} onChange={e => set('occupation', { CompanyName: e.target.value })} className={inputCls} /></Field>
                <Field label="Annual income"><input type="number" min={0} placeholder="in your local currency" value={data.occupation.AnnualIncome} onChange={e => set('occupation', { AnnualIncome: e.target.value })} className={inputCls} /></Field>
                <Field label="Work location"><input value={data.occupation.WorkLocation} onChange={e => set('occupation', { WorkLocation: e.target.value })} className={inputCls} /></Field>
              </div>
            </div>
          )}

          {step === 3 && (
            <div>
              <StepHeader title="Family & lifestyle" subtitle="A few details about your family and everyday habits" />
              <p className="mb-3 flex items-center gap-1.5 text-xs font-medium uppercase tracking-wide text-white/40">
                <Users className="size-3.5" /> Family
              </p>
              <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
                <Field label="Family type">
                  <PillGroup value={data.family.FamilyType} onChange={v => set('family', { FamilyType: v })} options={[{ value: 'nuclear', label: 'Nuclear' }, { value: 'joint', label: 'Joint' }]} />
                </Field>
                <Field label="Family status">
                  <PillGroup
                    value={data.family.FamilyStatus}
                    onChange={v => set('family', { FamilyStatus: v })}
                    options={[{ value: 'middle_class', label: 'Middle Class' }, { value: 'upper_middle_class', label: 'Upper Middle' }, { value: 'rich', label: 'Rich' }, { value: 'affluent', label: 'Affluent' }]}
                    columns={2}
                  />
                </Field>
                <Field label="Father's name"><input value={data.family.FatherName} onChange={e => set('family', { FatherName: e.target.value })} className={inputCls} /></Field>
                <Field label="Father's occupation"><input value={data.family.FatherOccupation} onChange={e => set('family', { FatherOccupation: e.target.value })} className={inputCls} /></Field>
                <Field label="Mother's name"><input value={data.family.MotherName} onChange={e => set('family', { MotherName: e.target.value })} className={inputCls} /></Field>
                <Field label="Mother's occupation"><input value={data.family.MotherOccupation} onChange={e => set('family', { MotherOccupation: e.target.value })} className={inputCls} /></Field>
                <Field label="Brothers"><input type="number" min={0} value={data.family.Brothers} onChange={e => set('family', { Brothers: e.target.value })} className={inputCls} /></Field>
                <Field label="Sisters"><input type="number" min={0} value={data.family.Sisters} onChange={e => set('family', { Sisters: e.target.value })} className={inputCls} /></Field>
              </div>

              <p className="mb-3 mt-7 flex items-center gap-1.5 text-xs font-medium uppercase tracking-wide text-white/40">
                <UtensilsCrossed className="size-3.5" /> Lifestyle
              </p>
              <Field label="Diet">
                <PillGroup
                  value={data.lifestyle.Diet}
                  onChange={v => set('lifestyle', { Diet: v })}
                  options={[{ value: 'vegetarian', label: 'Vegetarian' }, { value: 'non_vegetarian', label: 'Non-Vegetarian' }, { value: 'eggetarian', label: 'Eggetarian' }, { value: 'vegan', label: 'Vegan' }]}
                  columns={2}
                />
              </Field>
              <div className="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-2">
                <Field label="Smoking">
                  <PillGroup value={data.lifestyle.Smoking ? 'yes' : 'no'} onChange={v => set('lifestyle', { Smoking: v === 'yes' })} options={[{ value: 'no', label: 'No' }, { value: 'yes', label: 'Yes' }]} />
                </Field>
                <Field label="Drinking">
                  <PillGroup value={data.lifestyle.Drinking ? 'yes' : 'no'} onChange={v => set('lifestyle', { Drinking: v === 'yes' })} options={[{ value: 'no', label: 'No' }, { value: 'yes', label: 'Yes' }]} />
                </Field>
              </div>
              <div className="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-2">
                <Field label="Hobbies" hint="Comma separated"><input value={data.lifestyle.Hobbies} onChange={e => set('lifestyle', { Hobbies: e.target.value })} placeholder="e.g. reading, cricket, travel" className={inputCls} /></Field>
                <Field label="Languages known" hint="Comma separated"><input value={data.lifestyle.LanguagesKnown} onChange={e => set('lifestyle', { LanguagesKnown: e.target.value })} placeholder="e.g. Urdu, English, Hindi" className={inputCls} /></Field>
              </div>
            </div>
          )}

          {step === 4 && (
            <div>
              <StepHeader title="Location & preferences" subtitle="Where you live, and who you're hoping to meet" />
              <p className="mb-3 flex items-center gap-1.5 text-xs font-medium uppercase tracking-wide text-white/40">
                <MapPin className="size-3.5" /> Your location
              </p>
              <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
                <Field label="Country" required><input value={data.location.Country} onChange={e => set('location', { Country: e.target.value })} className={inputCls} /></Field>
                <Field label="State" required><input value={data.location.State} onChange={e => set('location', { State: e.target.value })} className={inputCls} /></Field>
                <Field label="City" required><input value={data.location.City} onChange={e => set('location', { City: e.target.value })} className={inputCls} /></Field>
                <Field label="Pincode"><input value={data.location.Pincode} onChange={e => set('location', { Pincode: e.target.value })} className={inputCls} /></Field>
              </div>
              <Field label="Address" className="mt-5">
                <textarea rows={2} value={data.location.Address} onChange={e => set('location', { Address: e.target.value })} className={`${inputCls} resize-none`} />
              </Field>

              <p className="mb-3 mt-7 flex items-center gap-1.5 text-xs font-medium uppercase tracking-wide text-white/40">
                <Sparkles className="size-3.5" /> Partner preferences
              </p>
              <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
                <Field label="Min age"><input type="number" min={18} max={99} value={data.preferences.MinAge} onChange={e => set('preferences', { MinAge: e.target.value })} className={inputCls} /></Field>
                <Field label="Max age"><input type="number" min={18} max={99} value={data.preferences.MaxAge} onChange={e => set('preferences', { MaxAge: e.target.value })} className={inputCls} /></Field>
                <Field label="Min height (cm)"><input type="number" min={100} max={250} value={data.preferences.MinHeight} onChange={e => set('preferences', { MinHeight: e.target.value })} className={inputCls} /></Field>
                <Field label="Max height (cm)"><input type="number" min={100} max={250} value={data.preferences.MaxHeight} onChange={e => set('preferences', { MaxHeight: e.target.value })} className={inputCls} /></Field>
                <Field label="Preferred religion" hint="Comma separated"><input value={data.preferences.Religion} onChange={e => set('preferences', { Religion: e.target.value })} placeholder="e.g. Islam" className={inputCls} /></Field>
                <Field label="Preferred caste" hint="Comma separated"><input value={data.preferences.Caste} onChange={e => set('preferences', { Caste: e.target.value })} className={inputCls} /></Field>
                <Field label="Preferred education" hint="Comma separated"><input value={data.preferences.Education} onChange={e => set('preferences', { Education: e.target.value })} className={inputCls} /></Field>
                <Field label="Preferred occupation" hint="Comma separated"><input value={data.preferences.Occupation} onChange={e => set('preferences', { Occupation: e.target.value })} className={inputCls} /></Field>
                <Field label="Preferred country"><input value={data.preferences.Country} onChange={e => set('preferences', { Country: e.target.value })} className={inputCls} /></Field>
                <Field label="Preferred state"><input value={data.preferences.State} onChange={e => set('preferences', { State: e.target.value })} className={inputCls} /></Field>
                <Field label="Preferred city"><input value={data.preferences.City} onChange={e => set('preferences', { City: e.target.value })} className={inputCls} /></Field>
              </div>
            </div>
          )}

          {step === 5 && (
            <div>
              <StepHeader title="About you" subtitle="A short introduction, then review everything before you finish" />
              <Field label="About me" required hint={`${data.profile.AboutMe.length}/600`}>
                <textarea
                  rows={5} maxLength={600}
                  value={data.profile.AboutMe}
                  onChange={e => set('profile', { AboutMe: e.target.value })}
                  placeholder="Share your story, values, and what you're looking for in a life partner…"
                  className={`${inputCls} resize-none`}
                />
              </Field>

              <div className="mt-8 space-y-3">
                <p className="text-xs font-medium uppercase tracking-wide text-white/40">Review your profile</p>
                <ReviewGroup title="Basic" icon={User} rows={[
                  ['Gender', data.profile.Gender], ['Date of birth', data.profile.DateOfBirth],
                  ['Height', data.profile.Height && `${data.profile.Height} cm`], ['Weight', data.profile.Weight && `${data.profile.Weight} kg`],
                  ['Marital status', data.profile.MaritalStatus.replace(/_/g, ' ')], ['Blood group', data.profile.BloodGroup],
                ]} />
                <ReviewGroup title="Religion & community" icon={Landmark} rows={[
                  ['Religion', data.profile.Religion], ['Sect', data.profile.Sect], ['Caste', data.profile.Caste],
                  ['Sub-caste', data.profile.SubCaste], ['Mother tongue', data.profile.MotherTongue],
                ]} />
                <ReviewGroup title="Education & career" icon={GraduationCap} rows={[
                  ['Qualification', data.education.Qualification], ['College', data.education.College],
                  ['Occupation', data.occupation.Occupation], ['Company', data.occupation.CompanyName],
                  ['Work location', data.occupation.WorkLocation],
                ]} />
                <ReviewGroup title="Family & lifestyle" icon={Users} rows={[
                  ['Family type', data.family.FamilyType.replace(/_/g, ' ')], ['Father', data.family.FatherName],
                  ['Mother', data.family.MotherName], ['Diet', data.lifestyle.Diet.replace(/_/g, ' ')],
                  ['Hobbies', data.lifestyle.Hobbies],
                ]} />
                <ReviewGroup title="Location" icon={MapPin} rows={[
                  ['City', data.location.City], ['State', data.location.State], ['Country', data.location.Country],
                ]} />
              </div>
            </div>
          )}

          {error && <p className="mt-6 rounded-lg bg-red-500/10 p-3 text-sm text-red-400">{error}</p>}

          <div className="mt-8 flex items-center justify-between border-t border-white/8 pt-6">
            <button
              type="button"
              onClick={() => setStep(s => Math.max(0, s - 1))}
              disabled={step === 0 || saving}
              className="flex cursor-pointer items-center gap-1.5 rounded-lg px-4 py-2.5 text-sm font-medium text-white/60 transition-colors duration-150 hover:text-white disabled:cursor-not-allowed disabled:opacity-30"
            >
              <ChevronLeft className="size-4" /> Back
            </button>

            <div className="flex items-center gap-3">
              {savedStep === step && !saving && (
                <span className="flex items-center gap-1 text-xs text-emerald-400">
                  <Check className="size-3.5" /> Saved
                </span>
              )}
              {step < STEPS.length - 1 ? (
                <button
                  type="button"
                  onClick={handleNext}
                  disabled={saving}
                  className="flex cursor-pointer items-center gap-1.5 rounded-lg bg-emerald-500 px-5 py-2.5 text-sm font-medium text-emerald-950 transition-colors duration-150 hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {saving ? <Loader2 className="size-4 animate-spin" /> : <>Continue <ChevronRight className="size-4" /></>}
                </button>
              ) : (
                <button
                  type="button"
                  onClick={handleFinish}
                  disabled={saving}
                  className="flex cursor-pointer items-center gap-1.5 rounded-lg bg-emerald-500 px-5 py-2.5 text-sm font-medium text-emerald-950 transition-colors duration-150 hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {saving ? <Loader2 className="size-4 animate-spin" /> : <>Complete profile <Check className="size-4" /></>}
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ------------------------------- subcomponents ------------------------------ */

const inputCls = 'w-full rounded-lg border border-white/10 bg-white/[0.03] px-4 py-2.5 text-white outline-none transition-colors placeholder:text-white/30 focus:border-emerald-500/60 focus:ring-3 focus:ring-emerald-500/15';

function StepHeader({ title, subtitle }: { title: string; subtitle: string }) {
  return (
    <div className="mb-7">
      <h2 className="text-xl font-semibold tracking-tight">{title}</h2>
      <p className="mt-1 text-sm text-white/50">{subtitle}</p>
    </div>
  );
}

function Field({ label, required, hint, icon: Icon, className = '', children }: {
  label: string; required?: boolean; hint?: string; icon?: React.ComponentType<{ className?: string }>; className?: string; children: React.ReactNode;
}) {
  return (
    <div className={className}>
      <label className="mb-1.5 flex items-center justify-between text-sm font-medium text-white/70">
        <span className="flex items-center gap-1.5">
          {Icon && <Icon className="size-3.5 text-white/40" />}
          {label} {required && <span className="text-amber-400">*</span>}
        </span>
        {hint && <span className="text-xs font-normal text-white/35">{hint}</span>}
      </label>
      {children}
    </div>
  );
}

function PillGroup({ value, onChange, options, columns = 3 }: {
  value: string; onChange: (v: string) => void; options: { value: string; label: string }[]; columns?: number;
}) {
  const colClass = columns === 4 ? 'grid-cols-4' : columns === 2 ? 'grid-cols-2' : 'grid-cols-3';
  return (
    <div className={`grid ${colClass} gap-2`}>
      {options.map(opt => (
        <button
          key={opt.value}
          type="button"
          onClick={() => onChange(opt.value)}
          className={`cursor-pointer rounded-lg border px-3 py-2.5 text-sm font-medium transition-colors duration-150 ${
            value === opt.value
              ? 'border-emerald-500/50 bg-emerald-500/10 text-emerald-400'
              : 'border-white/10 text-white/50 hover:border-white/20 hover:text-white/80'
          }`}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}

function Stepper({ step, onJump }: { step: number; onJump: (i: number) => void }) {
  return (
    <div className="flex items-center">
      {STEPS.map((s, i) => {
        const Icon = s.icon;
        const stateCls = i < step
          ? 'border-emerald-500 bg-emerald-500 text-emerald-950'
          : i === step
            ? 'border-emerald-500 bg-emerald-500/10 text-emerald-400'
            : 'border-white/15 text-white/30';
        return (
          <div key={s.key} className="flex flex-1 items-center last:flex-none">
            <button
              type="button"
              onClick={() => onJump(i)}
              className={`flex cursor-pointer flex-col items-center gap-1.5 ${i > step ? 'cursor-default' : ''}`}
            >
              <span className={`flex size-9 items-center justify-center rounded-full border-2 transition-colors duration-200 ${stateCls}`}>
                {i < step ? <Check className="size-4" /> : <Icon className="size-4" />}
              </span>
              <span className={`hidden text-[11px] font-medium sm:block ${i <= step ? 'text-white/70' : 'text-white/30'}`}>{s.label}</span>
            </button>
            {i < STEPS.length - 1 && (
              <div className={`mx-2 h-0.5 flex-1 rounded-full transition-colors duration-200 ${i < step ? 'bg-emerald-500' : 'bg-white/10'}`} />
            )}
          </div>
        );
      })}
    </div>
  );
}

function CompletionRing({ percent }: { percent: number }) {
  const size = 64; const stroke = 6; const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const offset = c - (percent / 100) * c;
  return (
    <div className="relative shrink-0" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={r} stroke="currentColor" strokeWidth={stroke} fill="none" className="text-white/10" />
        <circle
          cx={size / 2} cy={size / 2} r={r} stroke="currentColor" strokeWidth={stroke} fill="none"
          strokeDasharray={c} strokeDashoffset={offset} strokeLinecap="round"
          className="text-emerald-400 transition-[stroke-dashoffset] duration-500 ease-out"
        />
      </svg>
      <span className="absolute inset-0 flex items-center justify-center text-sm font-semibold text-white">{percent}%</span>
    </div>
  );
}

function ReviewGroup({ title, icon: Icon, rows }: { title: string; icon: React.ComponentType<{ className?: string }>; rows: [string, string | false | undefined][] }) {
  const filled = rows.filter(([, v]) => v);
  return (
    <div className="rounded-xl border border-white/8 bg-white/[0.02] p-4">
      <p className="flex items-center gap-1.5 text-sm font-medium text-white/80">
        <Icon className="size-3.5 text-emerald-400" /> {title}
      </p>
      {filled.length === 0 ? (
        <p className="mt-2 text-xs text-white/35">Not filled in yet</p>
      ) : (
        <dl className="mt-2 grid grid-cols-2 gap-x-4 gap-y-1.5 sm:grid-cols-3">
          {filled.map(([k, v]) => (
            <div key={k}>
              <dt className="text-[11px] text-white/35">{k}</dt>
              <dd className="truncate text-sm text-white/75 capitalize">{v}</dd>
            </div>
          ))}
        </dl>
      )}
    </div>
  );
}
