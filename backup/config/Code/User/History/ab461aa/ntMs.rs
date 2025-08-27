use rand::Rng;
use std::{cmp::Ordering, io};
use colored::{Colorize};


fn print_red(text: &str, bold:bool, italic:bool){
    let red_string= String::from(text).red();
    println!("{}", red_string);
}

fn main() {
    /* Generating a random number between 0 and 100 */
    let rand_num = rand::rng().random_range(0..100);

    /* Tracking user error */
    let mut count = 0;

    /* Looping to continue the game. */
    loop {
        if count < 5 {

            /* Getting user's input */
            println!("{}",String::from("Guess the number (Press 'q' to quit): ").blue().bold());
            let mut input = String::new();
            io::stdin()
                .read_line(&mut input)
                .expect("Please enter a proper integer");

            /* Prasing the input */
            let input: u64 = match input
                            .trim()
                            .parse() {
                Ok(num) => {
                    num
                },
                Err(_) => {
                    print_red("Please enter a valid number.", true, false);
                    continue;
                },
            };

            /* Increase count only if parsing succeeds. */
            count += 1;

            /* Checking and mapping user's input to relevant situation */
            match input.cmp(&rand_num) {
                Ordering::Less => {
                    println!("{}", String::from("The number you have guessed is too low. Guess higher!").red().bold());
                    continue;
                }
                Ordering::Greater => {
                    println!("{}", String::from("The number you have guessed is too high. Guess lower!").red().bold());
                    continue;
                }
                Ordering::Equal => {
                    println!("{}", String::from("Perfect! You Win! You needed {count} tries to win!").green().bold());
                    break;
                }
            }
        } else {
            println!("{}", String::from("You have guessed wrong 5 times.").red().bold().italic());
            println!("{}", String::from("You have guesses wrong 5 times.\nGame Over You Loser!!!!").red().bold().italic());
            break;
        }
    }
}
