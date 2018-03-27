//
//  ColorPickerTableViewCell.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 3/7/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import UIKit

/**
    Custom cell for displaying and selecting a color for a tag.
 
    - Note: There is one button for each of the 15 color options. The background color of the button is used to display the color option that the button represents. Each button's tag value matches its number so the `didTapColor` function knows which color called it.
 */
class ColorPickerTableViewCell: UITableViewCell {

  /// Outlet to the button representing the first (0th) color.
  @IBOutlet weak var colorButtonZero: UIButton!
  
  /// Outlet to the button representing the second color.
  @IBOutlet weak var colorButtonOne: UIButton!
  
  /// Outlet to the button representing the third color.
  @IBOutlet weak var colorButtonTwo: UIButton!
  
  /// Outlet to the button representing the fourth color.
  @IBOutlet weak var colorButtonThree: UIButton!
  
  /// Outlet to the button representing the fifth color.
  @IBOutlet weak var colorButtonFour: UIButton!
  
  /// Outlet to the button representing the sixth color.
  @IBOutlet weak var colorButtonFive: UIButton!
  
  /// Outlet to the button representing the seventh color.
  @IBOutlet weak var colorButtonSix: UIButton!
  
  /// Outlet to the button representing the eighth color.
  @IBOutlet weak var colorButtonSeven: UIButton!
  
  /// Outlet to the button representing the ninth color.
  @IBOutlet weak var colorButtonEight: UIButton!
  
  /// Outlet to the button representing the tenth color.
  @IBOutlet weak var colorButtonNine: UIButton!
  
  /// Outlet to the button representing the eleventh color.
  @IBOutlet weak var colorButtonTen: UIButton!
  
  /// Outlet to the button representing the twelfth color.
  @IBOutlet weak var colorButtonEleven: UIButton!
  
  /// Outlet to the button representing the thirteenth color.
  @IBOutlet weak var colorButtonTwelve: UIButton!
  
  /// Outlet to the button representing the fourteenth color.
  @IBOutlet weak var colorButtonThirteen: UIButton!
  
  /// Outlet to the button representing the fifteenth color.
  @IBOutlet weak var colorButtonFourteen: UIButton!
  
  /// Delegate which allows the cell to notify the controller of user interaction within the cell.
  var delegate: ColorPickerTableViewCellDelegate?
  
  
  /// Used to set the background color and corner radius (to make them circular) for each color button.
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // set background colors
    colorButtonZero.backgroundColor = TagConstants.colorFor(index: 0)
    colorButtonOne.backgroundColor = TagConstants.colorFor(index: 1)
    colorButtonTwo.backgroundColor = TagConstants.colorFor(index: 2)
    colorButtonThree.backgroundColor = TagConstants.colorFor(index: 3)
    colorButtonFour.backgroundColor = TagConstants.colorFor(index: 4)
    colorButtonFive.backgroundColor = TagConstants.colorFor(index: 5)
    colorButtonSix.backgroundColor = TagConstants.colorFor(index: 6)
    colorButtonSeven.backgroundColor = TagConstants.colorFor(index: 7)
    colorButtonEight.backgroundColor = TagConstants.colorFor(index: 8)
    colorButtonNine.backgroundColor = TagConstants.colorFor(index: 9)
    colorButtonTen.backgroundColor = TagConstants.colorFor(index: 10)
    colorButtonEleven.backgroundColor = TagConstants.colorFor(index: 11)
    colorButtonTwelve.backgroundColor = TagConstants.colorFor(index: 12)
    colorButtonThirteen.backgroundColor = TagConstants.colorFor(index: 13)
    colorButtonFourteen.backgroundColor = TagConstants.colorFor(index: 14)
    
    // set all corner radii
    colorButtonZero.layer.cornerRadius = 20
    colorButtonOne.layer.cornerRadius = 20
    colorButtonTwo.layer.cornerRadius = 20
    colorButtonThree.layer.cornerRadius = 20
    colorButtonFour.layer.cornerRadius = 20
    colorButtonFive.layer.cornerRadius = 20
    colorButtonSix.layer.cornerRadius = 20
    colorButtonSeven.layer.cornerRadius = 20
    colorButtonEight.layer.cornerRadius = 20
    colorButtonNine.layer.cornerRadius = 20
    colorButtonTen.layer.cornerRadius = 20
    colorButtonEleven.layer.cornerRadius = 20
    colorButtonTwelve.layer.cornerRadius = 20
    colorButtonThirteen.layer.cornerRadius = 20
    colorButtonFourteen.layer.cornerRadius = 20
  }
  
  /**
      Sets the image of one color button to a checkmark to show that it is the selected image for the tag.
   
      - Parameters:
          - colorIndex: The index of the color button to be checkmarked.
   */
  func setCheckedColor(colorIndex: Int) {
    
    // Clear all color button images (so just one has the checkmark image)
    colorButtonZero.setImage(UIImage(), for: .normal)
    colorButtonOne.setImage(UIImage(), for: .normal)
    colorButtonTwo.setImage(UIImage(), for: .normal)
    colorButtonThree.setImage(UIImage(), for: .normal)
    colorButtonFour.setImage(UIImage(), for: .normal)
    colorButtonFive.setImage(UIImage(), for: .normal)
    colorButtonSix.setImage(UIImage(), for: .normal)
    colorButtonSeven.setImage(UIImage(), for: .normal)
    colorButtonEight.setImage(UIImage(), for: .normal)
    colorButtonNine.setImage(UIImage(), for: .normal)
    colorButtonTen.setImage(UIImage(), for: .normal)
    colorButtonEleven.setImage(UIImage(), for: .normal)
    colorButtonTwelve.setImage(UIImage(), for: .normal)
    colorButtonThirteen.setImage(UIImage(), for: .normal)
    colorButtonFourteen.setImage(UIImage(), for: .normal)
    
    // Checkmark one color button
    let checkMarkImage = UIImage(named: IconNameConstants.checkmark)
    switch colorIndex {
    case 0:
      colorButtonZero.setImage(checkMarkImage, for: .normal)
      break
    case 1:
      colorButtonOne.setImage(checkMarkImage, for: .normal)
      break
    case 2:
      colorButtonTwo.setImage(checkMarkImage, for: .normal)
      break
    case 3:
      colorButtonThree.setImage(checkMarkImage, for: .normal)
      break
    case 4:
      colorButtonFour.setImage(checkMarkImage, for: .normal)
      break
    case 5:
      colorButtonFive.setImage(checkMarkImage, for: .normal)
      break
    case 6:
      colorButtonSix.setImage(checkMarkImage, for: .normal)
      break
    case 7:
      colorButtonSeven.setImage(checkMarkImage, for: .normal)
      break
    case 8:
      colorButtonEight.setImage(checkMarkImage, for: .normal)
      break
    case 9:
      colorButtonNine.setImage(checkMarkImage, for: .normal)
      break
    case 10:
      colorButtonTen.setImage(checkMarkImage, for: .normal)
      break
    case 11:
      colorButtonEleven.setImage(checkMarkImage, for: .normal)
      break
    case 12:
      colorButtonTwelve.setImage(checkMarkImage, for: .normal)
      break
    case 13:
      colorButtonThirteen.setImage(checkMarkImage, for: .normal)
      break
    case 14:
      colorButtonFourteen.setImage(checkMarkImage, for: .normal)
      break
    default:
      break
    }
  }
  
  /// Called when the user taps on one of the color buttons to update the delegate.
  @IBAction func didTapColor(_ sender: UIButton) {
    let colorIndex = sender.tag // works because each button's tag value matches the color index it represents
    delegate?.didTap(colorIndex: colorIndex)
  }
}

/// Delegate for the `ColorPickerTableViewCell` to tell its controller of any user interaction within it.
protocol ColorPickerTableViewCellDelegate {
  
  /**
      Tells the delegate that the user tapped a color button.
     
      - Parameters:
          - colorIndex: The index of the newly selected color.
   */
  func didTap(colorIndex: Int)
}
