import React, { useState } from 'react';

const KNOWLEDGE_BASE_CITIES = [
  'Amsterdam', 'Athens', 'Auckland', 'Bangkok', 'Barcelona', 'Beijing', 'Berlin',
  'Bogotá', 'Boston', 'Brussels', 'Budapest', 'Buenos Aires', 'Cairo', 'Cape Town',
  'Chicago', 'Chongqing', 'Copenhagen', 'Delhi', 'Dhaka', 'Dubai', 'Dublin',
  'Guangzhou', 'Hong Kong', 'Istanbul', 'Jakarta', 'Johannesburg', 'Karachi',
  'Kolkata', 'Lagos', 'Lima', 'Lisbon', 'London', 'Los Angeles', 'Madrid', 'Manila',
  'Melbourne', 'Mexico City', 'Moscow', 'Mumbai', 'New York', 'Osaka', 'Paris',
  'Rio de Janeiro', 'Rome', 'São Paulo', 'Seoul', 'Shanghai', 'Singapore', 'Sydney', 'Tokyo'
];

function CityInput({ value, onChange, onSubmit, disabled }) {
  const [showDropdown, setShowDropdown] = useState(false);

  const filteredCities = value
    ? KNOWLEDGE_BASE_CITIES.filter(city =>
        city.toLowerCase().includes(value.toLowerCase())
      )
    : KNOWLEDGE_BASE_CITIES;

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !disabled) {
      onSubmit();
    }
  };

  return (
    <div className="input-section">
      <label className="input-label">
        💡 Select from some popular cities with supplemental knowledge base data, or enter any city (even fictional ones!)
      </label>
      <div className="autocomplete-wrapper">
        <input
          type="text"
          placeholder="Enter or select a city name (e.g., Tokyo, Paris, New York)"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onFocus={() => setShowDropdown(true)}
          onBlur={() => setTimeout(() => setShowDropdown(false), 200)}
          onKeyPress={handleKeyPress}
          disabled={disabled}
          className="city-input"
        />
        {showDropdown && filteredCities.length > 0 && (
          <div className="city-dropdown">
            {filteredCities.map((city, index) => (
              <div
                key={index}
                className="city-option"
                onClick={() => {
                  onChange(city);
                  setShowDropdown(false);
                }}
              >
                {city}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default CityInput;
