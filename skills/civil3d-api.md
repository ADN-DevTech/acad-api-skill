# Civil 3D .NET API — Patterns & Best Practices

Civil 3D is a vertical toolset on AutoCAD. All base AutoCAD patterns apply.
All types and methods here are verified against the `Civil3D.NET` NuGet package public API (XML docs).

## Official References

| Resource | URL |
|----------|-----|
| Civil 3D .NET API Reference (2027) | https://help.autodesk.com/view/CIV3D/2027/ENU/ |
| Civil 3D NuGet (`Civil3D.NET`) | https://www.nuget.org/packages/Civil3D.NET |

## Namespaces

```csharp
using Autodesk.Civil.ApplicationServices;        // CivilApplication, CivilDocument
using Autodesk.Civil.DatabaseServices;           // Alignment, TinSurface, Profile, CogoPoint, Parcel, Corridor ...
using Autodesk.Civil.DatabaseServices.Styles;    // Style collections
using Autodesk.Civil.Settings;                   // Drawing/project settings
```

---

## Entry Point

Two ways to get `CivilDocument` — prefer the database overload when working from a non-active context:

```csharp
// Active document (returns null if not a Civil drawing)
CivilDocument civilDoc = CivilApplication.ActiveDocument;

// From a known database (safer for multi-doc scenarios)
CivilDocument civilDoc = CivilDocument.GetCivilDocument(db);

if (civilDoc == null)
{
    ed.WriteMessage("\nNot a Civil 3D drawing.");
    return;
}
```

---

## Collection Navigation

Civil 3D collections return `ObjectIdCollection`. Always resolve inside a transaction.

```csharp
using var tr = db.TransactionManager.StartTransaction();

// Top-level method-based collections on CivilDocument
foreach (ObjectId id in civilDoc.GetAlignmentIds())
{
    var alignment = tr.GetObject(id, OpenMode.ForRead) as Alignment;
    ed.WriteMessage($"\n{alignment.Name}  len={alignment.Length:F2}");
}

foreach (ObjectId id in civilDoc.GetSurfaceIds())
{
    var surface = tr.GetObject(id, OpenMode.ForRead) as TinSurface;
    ed.WriteMessage($"\n{surface.Name}");
}

// Pipe networks
foreach (ObjectId id in civilDoc.GetPipeNetworkIds())
{
    var net = tr.GetObject(id, OpenMode.ForRead) as Network;
}

// Sites → Parcels (parcels are children of a site)
foreach (ObjectId siteId in civilDoc.GetSiteIds())
{
    var site = tr.GetObject(siteId, OpenMode.ForRead) as Site;
    foreach (ObjectId parcelId in site.GetParcelIds())
    {
        var parcel = tr.GetObject(parcelId, OpenMode.ForRead) as Parcel;
        ed.WriteMessage($"\n  parcel: {parcel.Name}  area={parcel.Area:F2}");
    }
}

// Profiles are children of alignments — no top-level collection
foreach (ObjectId id in civilDoc.GetAlignmentIds())
{
    var alignment = tr.GetObject(id, OpenMode.ForRead) as Alignment;
    foreach (ObjectId profileId in alignment.GetProfileIds())
    {
        var profile = tr.GetObject(profileId, OpenMode.ForRead) as Profile;
        ed.WriteMessage($"\n  profile: {profile.Name}  parent={alignment.Name}");
    }
}

// Corridors — via property, not a Get*Ids method
foreach (ObjectId id in civilDoc.CorridorCollection)
{
    var corridor = tr.GetObject(id, OpenMode.ForRead) as Corridor;
    foreach (Baseline bl in corridor.Baselines)
    {
        var blAlignment = tr.GetObject(bl.AlignmentId, OpenMode.ForRead) as Alignment;
        ed.WriteMessage($"\n  baseline on: {blAlignment.Name}");
    }
}

tr.Commit();
```

**Key distinction:** Most Civil collections use `Get*Ids()` methods. Corridors use the `CorridorCollection` property. There is no `GetCorridorIds()`.

---

## COGO Points

### Read

```csharp
// COGO point collections can be very large — prefer index loop over LINQ
CogoPointCollection pts = civilDoc.CogoPoints;
for (int i = 0; i < pts.Count; i++)
{
    var pt = tr.GetObject(pts[i], OpenMode.ForRead) as CogoPoint;
    ed.WriteMessage($"\n#{pt.PointNumber}  {pt.Location}  {pt.RawDescription}");
}
```

### Add

```csharp
ObjectId ptId = civilDoc.CogoPoints.Add(new Point3d(x, y, z), true);
```

### Point Groups

```csharp
// Always check before adding — duplicate names throw
if (!civilDoc.PointGroups.Contains(groupName))
    civilDoc.PointGroups.Add(groupName);

// Build a point group query with number ranges
var query = new StandardPointGroupQuery();
query.IncludeNumbers = "1,2,3,5-10";   // comma-delimited and range syntax
pointGroup.SetQuery(query);
```

---

## Alignments

```csharp
var alignment = tr.GetObject(id, OpenMode.ForRead) as Alignment;

// Station + offset from a point (XY only — Z is ignored)
double station = 0, offset = 0;
alignment.StationOffset(new Point3d(x, y, 0), ref station, ref offset);

// Point at station + offset — outputs world coordinates
double outX = 0, outY = 0, outZ = 0;
alignment.PointLocation(station, offset, 0, ref outX, ref outY, ref outZ);
var pt = new Point3d(outX, outY, outZ);
```

---

## Surfaces

```csharp
var surface = tr.GetObject(id, OpenMode.ForRead) as TinSurface;

// FindElevationAtXY throws if the point is outside the surface boundary
try
{
    double z = surface.FindElevationAtXY(x, y);
}
catch (Exception)
{
    ed.WriteMessage($"\nPoint ({x:F2}, {y:F2}) is outside surface boundary.");
}

// Statistics
var props = surface.GetGeneralProperties();
ed.WriteMessage($"\nMin={props.MinimumElevation:F2}  Max={props.MaximumElevation:F2}");

// Modify: add point group as build definition, then rebuild
surface.UpgradeOpen();
surface.PointGroupsDefinition.AddPointGroup(pgId);
surface.Rebuild();
```

---

## Profiles

```csharp
var profile = tr.GetObject(profileId, OpenMode.ForRead) as Profile;

// Navigate to parent alignment
var alignment = tr.GetObject(profile.AlignmentId, OpenMode.ForRead) as Alignment;

// Elevation at station
double elev = profile.ElevationAt(station);
```

---

## Best Practices

**Null-check CivilDocument first.** Plain AutoCAD drawings return null from both `GetCivilDocument()` and `ActiveDocument`.

**Never iterate COGO points with LINQ on large drawings.** Point collections routinely hold thousands of objects. Index loops are significantly faster.

**Profiles are not top-level.** There is no `GetProfileIds()` on `CivilDocument`. Always go through the parent `Alignment`.

**Corridors use a property, not a method.** `CorridorCollection` is a property; `GetCorridorIds()` does not exist.

**Rebuild after surface edits.** Modifying `PointGroupsDefinition` does not auto-rebuild — call `surface.Rebuild()` explicitly.

**Check for duplicates before Add.** `PointGroups.Add()` throws on duplicate names. Always guard with `Contains()`.

**StationOffset is XY-only.** The Z component of the input point is ignored. Project to XY first when working with 3D coordinates.

---

## Code Sleuthing with `rg`

```bash
# Find SDK sample files covering a type
rg "TinSurface|CogoPoint|Alignment" "<ACAD_HOME>/C3D/Sample" --type cs -l

# See how a method is actually called in samples
rg "FindElevationAtXY" "<ACAD_HOME>/C3D/Sample" --type cs -C 5

# Find all command entry points in samples
rg "\[CommandMethod" "<ACAD_HOME>/C3D/Sample" --type cs -l
```
