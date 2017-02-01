//
//  ViewController.swift
//  SleepingInTheLibrary
//
//  Created by Jarrod Parkes on 11/3/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - ViewController: UIViewController

class ViewController: UIViewController {

    // MARK: Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var grabImageButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    // MARK: Actions
    
    @IBAction func grabNewImage(_ sender: AnyObject) {
        setUIEnabled(false)
        getImageFromFlickr()
    }

    // MARK: Configure UI
    
    private func setUIEnabled(_ enabled: Bool) {
        photoTitleLabel.isEnabled = enabled
        grabImageButton.isEnabled = enabled
        
        if enabled {
            grabImageButton.alpha = 1.0
        } else {
            grabImageButton.alpha = 0.5
        }
    }
    
    // MARK: Make Network Request
    
    private func getImageFromFlickr() {
        
        // TODO: Write the network code here!
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.GalleryPhotosMethod
            ,Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey
            ,Constants.FlickrParameterKeys.GalleryID: Constants.FlickrParameterValues.GalleryID
            ,Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL
            ,Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat
            ,Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        //[creating the url and request]
        let urlString = Constants.Flickr.APIBaseURL + scapedParameters(methodParameters as [String:AnyObject])
        let url = URL(string:urlString)!
        let request = URLRequest(url:url)
        
        print(url)
        
        //create the network request
        let task = URLSession.shared.dataTask(with: request){(data, response, error) in
           
            //if the error occurs, print it and re-anable the UI
            func displayError(_ error: String){
                print(error)
                print("URL at time of error: \(url)")
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                }
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else{
                displayError("There was an error with your request \(error)")
                return
            }
            
            /* GUARD: Did we gt a successful 2xx response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else{
                displayError("Your request returned a status code")
                return
            }
            
            /* GUARD: Was any data renurned? */
            guard let data = data else{
                displayError("No data was returned by the request!")
                return
            }
               
            //Parse the data
            let parseResult: [String: AnyObject]!
                do{
                    parseResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
                }catch{
                    displayError("Could not parse the data as JSON \(data)")
                    return
                }
            
            /* GUARD: Did Flickr return an error (stat != ok)*/
            guard let stat = parseResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else{
                displayError("Flickr API returned an error. See error code and message in \(parseResult)")
                return
            }
            
            /* GUARD: Are the "photos" and "photo" keys in our result? */
            guard let photosDictionary = parseResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]]else{
                displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)'")
                return
            }
            
            // Select a random photo
            let randomIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
            let photoInfo = photoArray[randomIndex]
            
            let photoTitle = photoInfo[Constants.FlickrResponseKeys.Title] as? String
            
            /* GUARD: Dose our photo have a key for 'url_m'*/
            guard let imageUrlString = photoInfo[Constants.FlickrResponseKeys.MediumURL] as? String else{
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photoInfo)")
                return
            }
                                
            let imageURL = URL(string:imageUrlString)
            if let imageData = try? Data(contentsOf:imageURL!){
                performUIUpdatesOnMain {
                    self.photoImageView.image = UIImage(data: imageData)
                    self.photoTitleLabel.text = photoTitle ?? "(Untitle)"
                    self.setUIEnabled(true)
                }
            }else{
                displayError("Could not parse the to a dictioanary")
                
            }
            
            
        }
        
        //start the task
        task.resume()
        
        
    }
    
    // MARK: Scape Parameters
    
    private func scapedParameters(_ parameters:[String:AnyObject]) -> String{
    
        if parameters.isEmpty{
            return ""
        }else{
        
            var keyValuePairs = [String]()
        
            for(key, value) in parameters{
                
                //make sure that is string value
                let stringValue = "\(value)"
                
                //scaping value
                let scapevalue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                
                //adding to key value pairs array
                keyValuePairs.append("\(key)=\(scapevalue)")
            }
        
            //return parameters string
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
}
