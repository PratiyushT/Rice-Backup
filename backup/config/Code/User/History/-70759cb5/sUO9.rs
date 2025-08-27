use std::iter::Filter;

// TODO: Implement the `in_progress` method. It must return an iterator over the tickets in
//  `TicketStore` with status set to `Status::InProgress`.
use ticket_fields::{TicketDescription, TicketTitle};

#[derive(Clone)]
pub struct TicketStore {
    tickets: Vec<Ticket>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct Ticket {
    pub title: TicketTitle,
    pub description: TicketDescription,
    pub status: Status,
}

#[derive(Clone, Debug, Copy, PartialEq)]
pub enum Status {
    ToDo,
    InProgress,
    Done,
}

impl TicketStore {
    pub fn new() -> Self {
        Self {
            tickets: Vec::new(),
        }
    }

    pub fn add_ticket(&mut self, ticket: Ticket) {
        self.tickets.push(ticket);
    }

    pub fn in_progress<'a>(&'a self) -> impl Trait
TicketStore::to_dos returns a Vec<&Ticket>.
That signature introduces a new heap allocation every time to_dos is called, which may be unnecessary depending on what the caller needs to do with the result. It'd be better if to_dos returned an iterator instead of a Vec, thus empowering the caller to decide whether to collect the results into a Vec or just iterate over them.

That's tricky though! What's the return type of to_dos, as implemented below?

impl TicketStore {
    pub fn to_dos(&self) -> ??? {
        self.tickets.iter().filter(|t| t.status == Status::ToDo)
    }
}
Unnameable types
The filter method returns an instance of std::iter::Filter, which has the following definition:

pub struct Filter<I, P> { /* fields omitted */ }
where I is the type of the iterator being filtered on and P is the predicate used to filter the elements.
We know that I is std::slice::Iter<'_, Ticket> in this case, but what about P?
P is a closure, an anonymous function. As the name suggests, closures don't have a name, so we can't write them down in our code.

Rust has a solution for this: impl Trait.

        self.tickets.iter()
        .filter(|ticket| ticket.status == Status::InProgress)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ticket_fields::test_helpers::{ticket_description, ticket_title};

    #[test]
    fn in_progress() {
        let mut store = TicketStore::new();

        let todo = Ticket {
            title: ticket_title(),
            description: ticket_description(),
            status: Status::ToDo,
        };
        store.add_ticket(todo);

        let in_progress = Ticket {
            title: ticket_title(),
            description: ticket_description(),
            status: Status::InProgress,
        };
        store.add_ticket(in_progress.clone());

        let in_progress_tickets: Vec<&Ticket> = store.in_progress().collect();
        assert_eq!(in_progress_tickets.len(), 1);
        assert_eq!(in_progress_tickets[0], &in_progress);
    }
}
