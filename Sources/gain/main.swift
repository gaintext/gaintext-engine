//
// GainText
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import Foundation

do {
    let command = GainCommand(args: CommandLine.arguments)
    try command.run()
} catch let e {
    print("error:", e)
}
