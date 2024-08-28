import SwiftUI
import Mantis
import AVFoundation
import SwiftfulLoadingIndicators

class CustomViewController: Mantis.CropViewController {
    var selectedImage : UIImage?
    var alertView: UIView?
    let toolbar = UIToolbar()
    let synthesizer = AVSpeechSynthesizer()
    var activityIndicator: UIActivityIndicatorView? // Activity Indicator per mostrare il caricamento
    var describeButton: UIBarButtonItem? // Riferimento al pulsante Describe
    var lastCustomQuestion: String? // Memorizza l'ultima domanda personalizzata


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configura i pulsanti come prima
        let describe = UIBarButtonItem(
            title: "Describe",
            style: .plain,
            target: self,
            action: #selector(onDescribeClicked)
        )
        
        //ne servono due diversi perché la toolbar se no da errore
        self.describeButton = describe

        
        let cancel = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(onCancelClicked)
        )
        
        let rotate = UIBarButtonItem(
            image: UIImage(systemName: "crop.rotate"),
            style: .plain,
            target: self,
            action: #selector(onRotateClicked)
        )
        
        let resetCropButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.counterclockwise"),
            style: .plain,
            target: self,
            action: #selector(onResetCropClicked)
        )
        
        let interruptButton = UIBarButtonItem(
            image: UIImage(systemName: "mic.fill.badge.xmark"),
            style: .plain,
            target: self,
            action: #selector(onInterruptClicked)
        )
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.setItems([cancel, flexibleSpace, interruptButton, rotate, resetCropButton, flexibleSpace, describe], animated: false)
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)
       
        NSLayoutConstraint.activate([
             toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
             toolbar.leftAnchor.constraint(equalTo: view.leftAnchor),
             toolbar.rightAnchor.constraint(equalTo: view.rightAnchor)
         ])
        
        self.activityIndicator = UIActivityIndicatorView(style: .large)
        self.activityIndicator?.center = self.view.center
        self.activityIndicator?.color = UIColor.blue
        self.view.addSubview(self.activityIndicator!)
    }

    
    @objc private func onDescribeClicked() {
        crop() // Salva l'immagine ritagliata prima di continuare
        
        DispatchQueue.main.async {
            self.selectedImage = ImageStorage.shared.croppedImage
        
            let alert = UIAlertController(title: "Choose question", message: "Please select a question to ask about the image", preferredStyle: .actionSheet)
            let questions = ["Describe this painting accurately", "What is there in this area?", "What is in the foreground?", "What is in the background?", "Provide a morphological description", "Describe the colors in this area","Custom question"]
            
            for question in questions {
                alert.addAction(UIAlertAction(title: question, style: .default) { action in
                    if question == "Custom question" {
                        // Se l'utente ha selezionato "Custom question", visualizza un alert separato per inserire una domanda personalizzata
                        self.presentCustomQuestionAlert(image: self.selectedImage!, question: question)
                    } else {
                        // Altrimenti, gestisci la selezione della domanda come prima
                        print("Selected question: \(question)")
                        self.describeButton?.isEnabled = false // Disabilita il pulsante Describe
                        self.activityIndicator?.startAnimating() // Avvia l'animazione dell'activity indicator
                        self.uploadingImage(image: self.selectedImage!, question: question)
                    }
                })
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // Presenta l'alert nel ViewController attuale
            self.present(alert, animated: true)
        }
    }
        
    @objc private func onCancelClicked() {
        synthesizer.stopSpeaking(at: .immediate)
        didSelectCancel()
    }
    
    @objc private func onInterruptClicked() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    @objc private func onRotateClicked() {
        didSelectClockwiseRotate()
    }
    
    @objc func onResetCropClicked() {
        didSelectReset()
    }
    
    
    private func presentCustomQuestionAlert(image: UIImage, question: String) {
        let customQuestionAlert = UIAlertController(title: "Custom Question", message: "Please enter your custom question", preferredStyle: .alert)
        
        // Aggiungi un campo di testo all'alert per l'inserimento del testo personalizzato
        customQuestionAlert.addTextField { textField in
                textField.placeholder = "Enter your question"
                textField.text = self.lastCustomQuestion // Imposta direttamente il testo con l'ultima domanda se esiste
                textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
            }
        
        // Aggiungi azioni all'alert
            let confirmAction = UIAlertAction(title: "Confirm", style: .default) { action in
                if let textField = customQuestionAlert.textFields?.first, let questionText = textField.text, !questionText.isEmpty {
                    // Aggiorno l'ultima domanda personalizzata con il nuovo input dell'utente
                    self.lastCustomQuestion = questionText
                    // Se l'utente ha inserito del testo, gestisci la logica qui
                    print("Custom question: \(questionText)")
                    self.describeButton?.isEnabled = false // Disabilita il pulsante Describe
                    self.activityIndicator?.startAnimating() // Avvia l'animazione dell'activity indicator
                    self.uploadingImage(image: image, question: questionText)
                }
            }
            confirmAction.isEnabled = self.lastCustomQuestion != nil && !self.lastCustomQuestion!.isEmpty // Abilita il pulsante se esiste già una domanda

            customQuestionAlert.addAction(confirmAction)
            customQuestionAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // Presenta l'alert nel ViewController attuale
            self.present(customQuestionAlert, animated: true)
    }
    
    //funzione per abilitare il pulsante conferma del customAlert nel caso in cui l'utente inizia a scrivere del testo
    @objc func textFieldDidChange(_ textField: UITextField) {
        // Ottieni l'alert corrente e il pulsante Conferma
        if let alertController = self.presentedViewController as? UIAlertController,
           let confirmAction = alertController.actions.first(where: { $0.title == "Confirm" }) {
            // Abilita il pulsante Confirm solo se il testo non è vuoto
            confirmAction.isEnabled = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }
    }
    
    private func uploadingImage(image: UIImage, question: String) {
        uploadImage(selectedImage: image, initialText: question) { generatedText, openAIDescription in
            // Questa chiusura viene eseguita quando il testo generato è pronto.
            print("Generated Text:", generatedText)
            print("OpenAI Description:", openAIDescription)
            
            let utterance = AVSpeechUtterance(string: generatedText)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-AU")
            utterance.rate = 0.5
            
            self.synthesizer.speak(utterance)
            
            //solo il thread principale può modificare la vista quindi facciamo cosi.
            DispatchQueue.main.async {
                self.activityIndicator?.stopAnimating() // Ferma l'animazione dell'activity indicator
                self.describeButton?.isEnabled = true // Riabilita il pulsante Describe
            }
        }
    }


}
