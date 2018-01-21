import Foundation

struct Feature {
    var tags: [String]
    var data: NSArray
}

struct Entity {
    var name: String?
    var uuid: UUID?
    var prob: Double?
    var sourceMlEngine: String?
    var dataSource: String?
    var data: Feature?
}

struct Relation {
    var srcId: Int64
    var targetId: Int64
    var predicate: String
    var uuid: UUID
    var prob: Double?
}

struct Assoc {
    var src: Int64
    var target: Int64
}

class KnowledgeBase {
    var db: Connection
    let formatter = DateFormatter()
    var timer : DispatchSourceTimer
    var workmem: SynchronizedArray<Assoc>

    let schemaDDL = """
          create table if not exists knowledge_base (
          rowid integer primary key AUTOINCREMENT,
          sourceEntity integer references knowledge_base,
          targetEntity integer references knowledge_base,
          path  text default '',
          name text,
          predicate text,
          factId text unique,
          confidenceProbability real,
          revision int,
          creationTime text,
          updateTime text,
          sourceMlEngine text,
          dataSource text,
          data text
        );
        create index if not exists id_index1
           on knowledge_base (sourceEntity, targetEntity);
        create index if not exists id_index2
           on knowledge_base (factId);
        create virtual table if not exists kb_fts USING fts5(tags);
  """

    init(dblocation: String) throws {
        self.formatter.dateFormat = "dd.MM.yyyy"
        self.workmem = SynchronizedArray<Assoc>()
        self.timer  = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        self.db = try Connection(dblocation)
        try db.execute(schemaDDL)
        try db.prepare("insert into knowledge_base (factId) values (?)").run(UUID().uuidString)
        try db.prepare("insert into kb_fts(tags) values ('')").run()
        self.timer.schedule(deadline: .now(), repeating: .milliseconds(10), leeway: .milliseconds(100))
        self.timer.setEventHandler   {
            self.inference()
        }
        self.timer.resume()
    }

    internal func nextRowId() -> Int64 {
        var rowid: Int64
        rowid = -1
        do {
            rowid = try db.scalar("select seq from sqlite_sequence where name='knowledge_base'") as! Int64
        } catch {
            NSLog(error.localizedDescription)
        }
        return rowid + 1
    }

    internal func path(id: Int64) -> String {
        var path: String
        path = ""
        do {
            let select = "select path from knowledge_base where sourceEntity = \(id)"
            path = try db.scalar(select) as! String
        } catch {
            NSLog(error.localizedDescription)
        }
        return path
    }

    internal func updateAssoc(assoc: Assoc) {
        var path: String
        if (assoc.src == assoc.target) {
            path = "/"
        } else {
            path = "\(self.path(id:assoc.src))\(assoc.src)/"
        }
        do {
            let stmt = try db.prepare("update knowledge_base set path = ? where sourceEntity = ? and targetEntity = ?")
            try stmt.run(path, assoc.src, assoc.target)
        }  catch {
            NSLog(error.localizedDescription)
        }
    }

    internal func dbdump() {
        print("dump db")
        do {
            let stmt = try db.prepare("select sourceEntity, targetEntity, path from knowledge_base")
            for row in stmt {
                print("--")
                for (index, name) in stmt.columnNames.enumerated() {
                    print ("\(name)=\(row[index]!)")
                    // id: Optional(1), email: Optional("alice@mac.com")
                }
            }
            print("--")
        } catch {
            NSLog(error.localizedDescription)
        }
    }

    internal func inference() {
        if(workmem.count > 0) {
            workmem.remove(at: 0, completion: { assoc in
                self.updateAssoc(assoc: assoc)
            })
        }
        //self.dbdump()
    }

    func AssertEntity(entity: Entity) -> Int64 {
        var ret: Int64
        ret = -1
        do {
            if entity.uuid == nil {
                return ret
            }
            let source = nextRowId()

            let stmt = try db.prepare("""
                        insert into knowledge_base (sourceEntity, targetEntity, factId, name, confidenceProbability, revision, creationTime, updateTime, sourceMlEngine, dataSource, data)
                        values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """)
            try stmt.run(source, source, entity.uuid!.uuidString, entity.name, entity.prob, 0, formatter.string(from: Date()),
                         formatter.string(from: Date()), entity.sourceMlEngine, entity.dataSource, try KnowledgeBase.Encode(tags: entity.data!.tags, vectors: entity.data!.data))
            let ftsInsert = try db.prepare(
                """
                        insert into kb_fts(tags)
                        values (?)
                    """
            )

            try ftsInsert.run(entity.data!.tags.joined(separator: " "))
            workmem.append(Assoc(src: source, target:source))
            ret = nextRowId() - 1
        } catch {
            NSLog("assert entity %s", error.localizedDescription)
        }
        return ret
    }

    func AssertRelation(rel: Relation) -> Int64 {
        var ret: Int64
        ret = -1

        do {
            let insert = try db.prepare (
                """
                        insert into knowledge_base (sourceEntity, targetEntity, predicate, factId, confidenceProbability, creationTime, updateTime)
                        values (?, ?, ?, ?, ?, ?, ?)
                    """
            )
            try insert.run(rel.srcId, rel.targetId, rel.predicate, rel.uuid.uuidString, rel.prob,
                           formatter.string(from: Date()), formatter.string(from: Date()))
            workmem.append(Assoc(src: rel.srcId, target:rel.targetId))
        } catch {
            NSLog("assert relation %s", error.localizedDescription)
        }
        return ret
    }

    func Find(factid: String) -> Entity {
        var ret: Entity
        ret = Entity(name: "", uuid: UUID(), prob:0, sourceMlEngine:"", dataSource:"", data: nil)
        do {
            let stmt = try db.prepare("select name, factId, sourceMlEngine, confidenceProbability, dataSource from knowledge_base where factId = ?")
            try stmt.run(factid)
            for row in stmt {
                for (index, name) in stmt.columnNames.enumerated() {
                    if row[index] == nil {
                        continue
                    }
                    switch name {
                    case "name":
                        ret.name = row[index] as! String
                    case "factId":
                        ret.uuid = UUID(uuidString: row[index] as! String)
                    case "sourceMlEngine":
                        ret.sourceMlEngine = row[index] as! String
                    case "confidenceProbability":
                        ret.prob = row[index] as! Double
                    case "dataSource":
                        ret.dataSource = row[index] as! String
                    default:
                        NSLog("missing col %s", name)
                    }
                }
            }
        } catch {
            NSLog(error.localizedDescription)
        }
        return ret;

    }

    static func Encode(tags:[String], vectors: NSArray) throws -> String {
        var data = [String: Any]()
        data["tags"] = tags
        //data["vectors"] = String.init(data: try JSONSerialization.data(withJSONObject: vectors, options: []), encoding: String.Encoding.utf8)
        data["vectors"] = vectors
        return String.init(data: try JSONSerialization.data(withJSONObject: data, options: []),encoding: String.Encoding.utf8)!
    }

    static func Decode(data: String) throws -> Dictionary<String, Any> {
        let obj = data.data(using: String.Encoding.utf8)!
        let dict = try JSONSerialization.jsonObject(with: obj, options: []) as! Dictionary<String, Any>
        return dict
    }

    static func nearestNeighbor(f1:NSArray, f2: NSArray) -> Bool {
        var minDistance = 1.0
        let Threshold = 0.5
        for dv1 in f1 {
            for dv2 in f2 {
                let v1 = dv1 as! NSArray
                let v2 = dv2 as! NSArray
                var delta = Array(repeating: 0.0, count: v1.count)
                for i in 0..<v1.count {
                    delta[i] = (v1[i] as! Double) - (v2[i] as! Double)
                }
                var distance = 0.0
                for i in 0..<delta.count {
                    distance += delta[i]*delta[i]
                }
                distance = sqrt(distance)
                if distance < minDistance {
                    minDistance = distance
                }
            }
        }
        return  !(minDistance > Threshold)
    }

    func Search(terms: [String]) -> [String] {
        var ret: [String]
        ret = []
        do {
            let termStr: String
            termStr = terms.joined(separator: " OR ")
            let stmt = try db.prepare("select name, data from knowledge_base where sourceEntity in (select rowid from kb_fts where kb_fts match '\(termStr)' order by rank);")
            var vec: NSArray?
            vec = nil
            for row in stmt {
                let dict = try? KnowledgeBase.Decode(data: row[1] as! String)
                if vec == nil {
                    vec = dict!["vectors"] as! NSArray
                    ret.append(row[0] as! String)
                } else {
                    if(KnowledgeBase.nearestNeighbor(f1: vec!, f2: dict!["vectors"] as! NSArray)) {
                        ret.append(row[0] as! String)
                    }
                }
            }
        } catch {
            NSLog(error.localizedDescription)
        }
        return ret;
    }

    func SearchExact(terms: [String]) -> [String] {
        var ret: [String]
        ret = []
        do {
            let termStr: String
            termStr = terms.joined(separator: " AND ")
            let stmt = try db.prepare("select factid from knowledge_base where sourceEntity in (select rowid from kb_fts where kb_fts match '\(termStr)' order by rank);")
            for row in stmt {
                for (index, _) in stmt.columnNames.enumerated() {
                    ret.append(row[index] as! String)
                }
            }
        } catch {
            NSLog(error.localizedDescription)
        }
        return ret;
    }

    func Assert(predicate: String, entity1: Entity, entity2: Entity) -> Int64 {
        let id1 = self.AssertEntity(entity: entity1)
        let id2 = self.AssertEntity(entity: entity2)
        return self.AssertRelation(rel: Relation(srcId: id1, targetId: id2, predicate: predicate, uuid: UUID(), prob: (entity1.prob ?? 0) * (entity2.prob ?? 0)))
    }

}
