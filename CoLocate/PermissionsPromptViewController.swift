//
//  PermissionsPromptViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class PermissionsPromptViewController: UIViewController {

    @IBOutlet weak var logoStrapline: UIView!
    @IBOutlet weak var logoStraplineLabel: UILabel!
    @IBOutlet weak var bodyHeadline: UILabel!
    @IBOutlet weak var bodyCopy: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        logoStrapline.backgroundColor = .nhsBlue
        logoStraplineLabel.textColor = .white
        logoStraplineLabel.text = "Coronavirus"
        bodyHeadline.text = "Data we need"
        bodyCopy.text = """
Bacon ipsum dolor amet chuck cupim ground round pig, swine pastrami rump strip steak bresaola jowl. Ball tip corned beef pastrami ribeye pork loin sausage capicola shankle brisket alcatra. Cupim ham short loin meatloaf pastrami. Pork beef boudin cow chislic short ribs pork belly jerky chicken chuck meatloaf prosciutto. Swine corned beef bresaola, strip steak salami sirloin kevin shank burgdoggen biltong prosciutto. Jowl hamburger prosciutto flank ribeye bacon frankfurter fatback kevin brisket corned beef porchetta short loin.

Strip steak cow chicken bresaola jowl kevin pork belly pork biltong. Tongue bresaola cupim biltong prosciutto shank ribeye kielbasa pork belly ground round t-bone. Ham hock chislic leberkas boudin shank chuck doner kevin tenderloin pork loin beef tongue ground round. Frankfurter pig bresaola beef, shoulder sirloin burgdoggen. Jowl short loin pastrami pork chop meatball. Alcatra pastrami chicken beef ribs swine venison doner turkey fatback picanha short loin strip steak buffalo cupim leberkas.
"""
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
