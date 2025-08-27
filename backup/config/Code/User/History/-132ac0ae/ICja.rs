// TODO: add the necessary `Clone` implementations (and invocations)
//  to get the code to compile.

pub fn summary(ticket: Ticket) -> (Ticket, Summary) {
    (ticket, ticket.summary())
}


pub struct Ticket {
    pub title: String,
    pub description: String,
    pub status: String,
}

impl Ticket {
    pub fn summary(self) -> Summary {
        Summary {
            title: self.clone().title,
            status: self.clone().status,
        }
    }
}

pub struct Summary {
    pub title: String,
    pub status: String,
}
