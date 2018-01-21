import Foundation

struct People {
    var uuid: UUID
    var name: String
}

struct Groups {
    var name: String
    var people: [People]
    var uuid: UUID?
}

class PeopleFriendsFamily {
    let schemaDDL = """
            create table if not exists people (
                id integer primary key AUTOINCREMENT,
                factId text unique,
                name text not null,
                attributes text
            );
            create index if not exists people_index
            on people (factId, id);
            create table if not exists groups (
                id integer primary key AUTOINCREMENT,
                lft INTEGER NOT NULL UNIQUE CHECK (lft > 0),
                rgt INTEGER NOT NULL UNIQUE CHECK (rgt > 1),
                name text NOT NULL,
                attributes text,
                factId text unique,
                people_id integer REFERENCES people(id)
            );
            create index if not exists groups_index
            on groups (people_id, id);
  """
    
    init(pkg: KnowledgeBase) throws {
        try pkg.db.execute(schemaDDL)
    }
    
}
